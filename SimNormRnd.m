function [Scrap Conform Rework] = SimNormRnd(cut,sig,RW,LSL,USL)

PS = normrnd(cut,sig,RW,1);
Scrap = length(PS(PS<=LSL));
Conform = length(PS(PS>LSL & PS<USL));
Rework = length(PS(PS>=USL));