from time import sleep

class Ads41():
    nbits = 12
    _reg_delay_ctrl = 'ads41_delay_ctrl'
    _reg_delay_val = 'ads41_delay_val'
    _reg_rst = 'ads41_hardware_rst'
    _reg_pll_lock = 'ads41_pll_lock'
    _reg_spi = 'ads41_spi_controller'
    def __init__(self, cfpga, num=0):
        self.cfpga = cfpga
        self.num = num

    def _get_regname(self, reg):
        return "%s%d" % (reg, self.num)

    def hw_reset(self):
        self.cfpga.write_int(self._get_regname(self._reg_rst), 0)
        sleep(0.001)
        self.cfpga.write_int(self._get_regname(self._reg_rst), 1)
        sleep(0.001)
        self.cfpga.write_int(self._get_regname(self._reg_rst), 0)

    def chip_rst(self):
        self.write_spi(0x0, 0b10)

    def stobe_mode(self):
        self.write_spi(0x25, 0b011)

    def data_mode(self):
        self.write_spi(0x25, 0)

    def increment_delay(self, n):
        self.cfpga.write_int(self._get_regname(self._reg_delay_val), 0xffff)
        for i in range(n):
            self.cfpga.write_int(self._get_regname(self._reg_delay_ctrl), 0)
            self.cfpga.write_int(self._get_regname(self._reg_delay_ctrl), 0xffff)

    def decrement_delay(self, n):
        self.cfpga.write_int(self._get_regname(self._reg_delay_val), 0x0)
        for i in range(n):
            self.cfpga.write_int(self._get_regname(self._reg_delay_ctrl), 0)
            self.cfpga.write_int(self._get_regname(self._reg_delay_ctrl), 0xffff)

    def test_strobe(self, d, bitwise=False):
        A = 0b101010101010
        B = 0b010101010101
        if not bitwise:
            errcnt = 0
            for i in range(len(d)-1):
                if d[i] == A:
                    if d[i+1] != B:
                        errcnt += 1
                elif d[i] == B:
                    if d[i+1] != A:
                        errcnt += 1
                else:
                    errcnt += 1
            return errcnt == 0
        else:
            errcnt = [0 for _ in range(self.nbits)]
            for b in range(self.nbits):
                for i in range(len(d)-1):
                    if (((d[i] >> b) & 1) + ((d[i+1] >> b) & 1)) != 1:
                        errcnt[b] += 1
            return errcnt

    def get_pll_lock(self):
        return self.cfpga.read_int(self._get_regname(self._reg_pll_lock))

    def write_spi(self, addr, data):
        payload = 0
        payload += ((addr & 0xff) << 8)
        payload += ((data & 0xff))
        spi_reg = self._get_regname(self._reg_spi)
        #cs = 0xff00
        cs = 0xff00
        self.cfpga.write_int(spi_reg, payload, word_offset=1)
        self.cfpga.write_int(spi_reg, cs, word_offset=0) # triggers transaction
        return self.cfpga.read_uint(spi_reg, word_offset=2)
        
    
