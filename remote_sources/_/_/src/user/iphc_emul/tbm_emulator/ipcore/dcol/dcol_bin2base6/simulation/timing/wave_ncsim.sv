
 
 
 



 

window new WaveWindow  -name  "Waves for BMG Example Design"
waveform  using  "Waves for BMG Example Design"


      waveform add -signals /dcol_bin2base6_tb/status
      waveform add -signals /dcol_bin2base6_tb/dcol_bin2base6_synth_inst/bmg_port/CLKA
      waveform add -signals /dcol_bin2base6_tb/dcol_bin2base6_synth_inst/bmg_port/ADDRA
      waveform add -signals /dcol_bin2base6_tb/dcol_bin2base6_synth_inst/bmg_port/DOUTA
console submit -using simulator -wait no "run"
