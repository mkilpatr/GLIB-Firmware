
 
 
 



 

window new WaveWindow  -name  "Waves for BMG Example Design"
waveform  using  "Waves for BMG Example Design"


      waveform add -signals /row_bin2base6_tb/status
      waveform add -signals /row_bin2base6_tb/row_bin2base6_synth_inst/bmg_port/CLKA
      waveform add -signals /row_bin2base6_tb/row_bin2base6_synth_inst/bmg_port/ADDRA
      waveform add -signals /row_bin2base6_tb/row_bin2base6_synth_inst/bmg_port/DOUTA
console submit -using simulator -wait no "run"
