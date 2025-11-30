y = ERP.bindata(32, :, 3); % your mean vector;
x = 1:numel(y);
std_dev = ERP.binerror(32, :, 3);
curve1 = y + std_dev;
curve2 = y - std_dev;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
fill(x2, inBetween, 'g');
hold on;
plot(x, y, 'r', 'LineWidth', 2);




plot(rand(1, 10));       % Plot some random data


% plot bell curve
load examgrades
x = grades(:,1);
pd = fitdist(x,'Normal');
x = [-3:.1:3];
y = normpdf(x,0,1);
plot(x,y)
area(x, y)