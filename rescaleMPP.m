function scaledTensor=rescaleMPP(tensorPmpp,temperatureDegree,temperatureCoefficientDegree)
    factor=1-temperatureCoefficientDegree*temperatureDegree;
    scaledTensor=tensorPmpp*factor;
end