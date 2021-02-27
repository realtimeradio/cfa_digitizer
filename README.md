# cfa_digitizer

To download:

```
git clone https://github.com/realtimeradio/cfa_digitizer
cd cfa_digitizer
git submodule init
git submodule update
ln -s mlib_devel/startsg startsg
```

To run:

```
# From the top-level of the repository
./startsg startsg.local.rtr-dev1
```

You may need to create a new `startsg.local` file if your installation paths differ from that used on the `rtr-dev1` server.

`cfa_digitizer_test.slx` is a Simulink test model, which targets an xc7k70t FPGA,and contains a White Rabbit core, and two 10GbE interfaces.
