function y = monthsCloudyOcc
    load ./CloudyData/matrix2010.mat 
    load ./CloudyData/matrix2011.mat 
    load ./CloudyData/matrix2012.mat 
    load ./CloudyData/matrix2013.mat 
    load ./CloudyData/matrix2014.mat 
    load ./CloudyData/matrix2015.mat 
    load ./CloudyData/matrix2016.mat 
    load ./CloudyData/matrix2017.mat
    load ./CloudyData/matrix2018.mat 
    load ./CloudyData/matrix2019.mat 
    
    gen10 = matrix2010(:,1);
    gen11 = matrix2011(:,1);
    gen12 = matrix2012(:,1);
    gen13 = matrix2013(:,1);
    gen14 = matrix2014(:,1);
    gen15 = matrix2015(:,1);
    gen16 = matrix2016(:,1);
    gen17 = matrix2017(:,1);
    gen18 = matrix2018(:,1);
    gen19 = matrix2019(:,1);
    
    gen = [gen10;gen11;gen12;gen13;gen14;gen15;gen16;gen17;gen18;gen19;0];
    
    feb10 = matrix2010(:,2);
    feb11 = matrix2011(:,2);
    feb12 = matrix2012(:,2);
    feb13 = matrix2013(:,2);
    feb14 = matrix2014(:,2);
    feb15 = matrix2015(:,2);
    feb16 = matrix2016(:,2);
    feb17 = matrix2017(:,2);
    feb18 = matrix2018(:,2);
    feb19 = matrix2019(:,2);
    
    feb = [feb10;feb11;feb12;feb13;feb14;feb15;feb16;feb17;feb18;feb19;0];
    
    mar10 = matrix2010(:,3);
    mar11 = matrix2011(:,3);
    mar12 = matrix2012(:,3);
    mar13 = matrix2013(:,3);
    mar14 = matrix2014(:,3);
    mar15 = matrix2015(:,3);
    mar16 = matrix2016(:,3);
    mar17 = matrix2017(:,3);
    mar18 = matrix2018(:,3);
    mar19 = matrix2019(:,3);
    
    mar = [mar10;mar11;mar12;mar13;mar14;mar15;mar16;mar17;mar18;mar19;0];
    
    apr10 = matrix2010(:,4);
    apr11 = matrix2011(:,4);
    apr12 = matrix2012(:,4);
    apr13 = matrix2013(:,4);
    apr14 = matrix2014(:,4);
    apr15 = matrix2015(:,4);
    apr16 = matrix2016(:,4);
    apr17 = matrix2017(:,4);
    apr18 = matrix2018(:,4);
    apr19 = matrix2019(:,4);
    
    apr = [apr10;apr11;apr12;apr13;apr14;apr15;apr16;apr17;apr18;apr19;0];
    
    may10 = matrix2010(:,5);
    may11 = matrix2011(:,5);
    may12 = matrix2012(:,5);
    may13 = matrix2013(:,5);
    may14 = matrix2014(:,5);
    may15 = matrix2015(:,5);
    may16 = matrix2016(:,5);
    may17 = matrix2017(:,5);
    may18 = matrix2018(:,5);
    may19 = matrix2019(:,5);
    
    may = [may10;may11;may12;may13;may14;may15;may16;may17;may18;may19;0];
    
    jun10 = matrix2010(:,6);
    jun11 = matrix2011(:,6);
    jun12 = matrix2012(:,6);
    jun13 = matrix2013(:,6);
    jun14 = matrix2014(:,6);
    jun15 = matrix2015(:,6);
    jun16 = matrix2016(:,6);
    jun17 = matrix2017(:,6);
    jun18 = matrix2018(:,6);
    jun19 = matrix2019(:,6);
    
    jun = [jun10;jun11;jun12;jun13;jun14;jun15;jun16;jun17;jun18;jun19;0];
    
    jul10 = matrix2010(:,7);
    jul11 = matrix2011(:,7);
    jul12 = matrix2012(:,7);
    jul13 = matrix2013(:,7);
    jul14 = matrix2014(:,7);
    jul15 = matrix2015(:,7);
    jul16 = matrix2016(:,7);
    jul17 = matrix2017(:,7);
    jul18 = matrix2018(:,7);
    jul19 = matrix2019(:,7);
    
    jul = [jul10;jul11;jul12;jul13;jul14;jul15;jul16;jul17;jul18;jul19;0];

    aug10 = matrix2010(:,8);
    aug11 = matrix2011(:,8);
    aug12 = matrix2012(:,8);
    aug13 = matrix2013(:,8);
    aug14 = matrix2014(:,8);
    aug15 = matrix2015(:,8);
    aug16 = matrix2016(:,8);
    aug17 = matrix2017(:,8);
    aug18 = matrix2018(:,8);
    aug19 = matrix2019(:,8);
    
    aug = [aug10;aug11;aug12;aug13;aug14;aug15;aug16;aug17;aug18;aug19;0];
    
    sep10 = matrix2010(:,9);
    sep11 = matrix2011(:,9);
    sep12 = matrix2012(:,9);
    sep13 = matrix2013(:,9);
    sep14 = matrix2014(:,9);
    sep15 = matrix2015(:,9);
    sep16 = matrix2016(:,9);
    sep17 = matrix2017(:,9);
    sep18 = matrix2018(:,9);
    sep19 = matrix2019(:,9);
    
    sep = [sep10;sep11;sep12;sep13;sep14;sep15;sep16;sep17;sep18;sep19;0];
    
    oct10 = matrix2010(:,10);
    oct11 = matrix2011(:,10);
    oct12 = matrix2012(:,10);
    oct13 = matrix2013(:,10);
    oct14 = matrix2014(:,10);
    oct15 = matrix2015(:,10);
    oct16 = matrix2016(:,10);
    oct17 = matrix2017(:,10);
    oct18 = matrix2018(:,10);
    oct19 = matrix2019(:,10);
    
    oct = [oct10;oct11;oct12;oct13;oct14;oct15;oct16;oct17;oct18;oct19;0];
    
    nov10 = matrix2010(:,11);
    nov11 = matrix2011(:,11);
    nov12 = matrix2012(:,11);
    nov13 = matrix2013(:,11);
    nov14 = matrix2014(:,11);
    nov15 = matrix2015(:,11);
    nov16 = matrix2016(:,11);
    nov17 = matrix2017(:,11);
    nov18 = matrix2018(:,11);
    nov19 = matrix2019(:,11);
    
    nov = [nov10;nov11;nov12;nov13;nov14;nov15;nov16;nov17;nov18;nov19;0];
    
    dec10 = matrix2010(:,12);
    dec11 = matrix2011(:,12);
    dec12 = matrix2012(:,12);
    dec13 = matrix2013(:,12);
    dec14 = matrix2014(:,12);
    dec15 = matrix2015(:,12);
    dec16 = matrix2016(:,12);
    dec17 = matrix2017(:,12);
    dec18 = matrix2018(:,12);
    dec19 = matrix2019(:,12);
    
    dec = [dec10;dec11;dec12;dec13;dec14;dec15;dec16;dec17;dec18;dec19;0];
    
    y = [gen,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec]
end
