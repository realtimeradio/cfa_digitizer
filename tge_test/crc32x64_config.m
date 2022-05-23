function crc32x64_config(this_block)

  this_block.setTopLevelLanguage('Verilog');

  this_block.setEntityName('crc32x64');

  % System Generator has to assume that your entity  has a combinational feed through; 
  %   if it  doesn't, then comment out the following line:
  %this_block.tagAsCombinational;

  this_block.addSimulinkInport('valid_in');
  this_block.addSimulinkInport('init_in');
  this_block.addSimulinkInport('data_in');

  this_block.addSimulinkOutport('valid_out');
  this_block.addSimulinkOutport('init_out');
  this_block.addSimulinkOutport('data_out');
  this_block.addSimulinkOutport('crc');

  valid_out_port = this_block.port('valid_out');
  valid_out_port.setType('UFix_1_0');
  valid_out_port.useHDLVector(false);

  init_out_port = this_block.port('init_out');
  init_out_port.setType('UFix_1_0');
  init_out_port.useHDLVector(false);

  data_out_port = this_block.port('data_out');
  data_out_port.setType('UFix_64_0');

  crc_port = this_block.port('crc');
  crc_port.setType('UFix_32_0');

  % -----------------------------
  if (this_block.inputTypesKnown)
    % do input type checking, dynamic output type and generic setup in this code block.

    if (this_block.port('valid_in').width ~= 1);
      this_block.setError('Input data type for port "valid_in" must have width=1.');
    end

    this_block.port('valid_in').useHDLVector(false);

    if (this_block.port('init_in').width ~= 1);
      this_block.setError('Input data type for port "init_in" must have width=1.');
    end

    this_block.port('init_in').useHDLVector(false);

    if (this_block.port('data_in').width ~= 64);
      this_block.setError('Input data type for port "data_in" must have width=64.');
    end

  end  % if(inputTypesKnown)
  % -----------------------------

  % -----------------------------
   if (this_block.inputRatesKnown)
     setup_as_single_rate(this_block,'clk','ce')
   end  % if(inputRatesKnown)
  % -----------------------------

    % (!) Set the inout port rate to be the same as the first input 
    %     rate. Change the following code if this is untrue.
    uniqueInputRates = unique(this_block.getInputRates);


  % Add addtional source files as needed.
  %  |-------------
  %  | Add files in the order in which they should be compiled.
  %  | If two files "a.vhd" and "b.vhd" contain the entities
  %  | entity_a and entity_b, and entity_a contains a
  %  | component of type entity_b, the correct sequence of
  %  | addFile() calls would be:
  %  |    this_block.addFile('b.vhd');
  %  |    this_block.addFile('a.vhd');
  %  |-------------

  %    this_block.addFile('');
  %    this_block.addFile('');
  this_block.addFile('crclut.v');
  this_block.addFile('crc32x64.v');

return;


% ------------------------------------------------------------

function setup_as_single_rate(block,clkname,cename) 
  inputRates = block.inputRates; 
  uniqueInputRates = unique(inputRates); 
  if (length(uniqueInputRates)==1 & uniqueInputRates(1)==Inf) 
    block.addError('The inputs to this block cannot all be constant.'); 
    return; 
  end 
  if (uniqueInputRates(end) == Inf) 
     hasConstantInput = true; 
     uniqueInputRates = uniqueInputRates(1:end-1); 
  end 
  if (length(uniqueInputRates) ~= 1) 
    block.addError('The inputs to this block must run at a single rate.'); 
    return; 
  end 
  theInputRate = uniqueInputRates(1); 
  for i = 1:block.numSimulinkOutports 
     block.outport(i).setRate(theInputRate); 
  end 
  block.addClkCEPair(clkname,cename,theInputRate); 
  return; 

% ------------------------------------------------------------

