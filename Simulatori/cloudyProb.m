function y=cloudyProb(x)
    a = length(find(x == 1));
    b = length(find(x == 2));
    c = length(find(x == 3));
    d = length(find(x == 4));
    len = length(x);
    l1 = a/len;
    l2 = b/len;
    l3 = c/len;
    l4 = d/len;
    y = [l1,l2,l3,l4];
end