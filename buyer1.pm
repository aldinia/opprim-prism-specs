dtmc

// maximum number of requests
const int n = 20;

// value of the purchase
const int a1 = 100;
const int a2 = 300;
// benefit
const int b1 = 15;
const int b2 = 60;

formula cost = (s=1) ? a1 : a2;
formula benefit = (s=1) ? b1 : b2;

module Buyer
s : [0..2] init 0;  // purchase type
cs: [0..2] init 0;  // clue set: 1 high standard, 2 low standard
req: [0..n] init 0; // requests counter

// choice of the purchase
[start] s=0 & req<n-> 0.5:(s'=1) + 0.5:(s'=2);
[] s=0 & req=n-> true;
// choice of the threat
[] s>0 & cs=0 -> 0.5:(cs'=1) + 0.5:(cs'=2);
[request] s>0 & cs>0 -> (req'=min(req+1,n));
[accept]  s>0 & cs>0 -> (s'=0) & (cs'=0);
[refuse]  s>0 & cs>0 -> (s'=0) & (cs'=0);

endmodule

const int tct = 150;  // cost threshold
const int bt = 50;    // benefit threshold
const double tpt1 = 0.15;  // threat 1 probability threshold
const double tpt2 = 0.25; // threat 2 probability threshold
const double pr1 = 0.05; // probability of security incident due to threat 1 
const double pr2; // probability of security incident due to threat 2 

formula insurance_cost = insurance ? (threat=1 ? max(12, cost * pr1 / 2) : max(36, cost * pr2 / 2)) : 0;
formula threat = cs; // threat is given by the clue set

// Rule taking into account only risk probability
// formula risk_policy = ((pt < tpt1) & (threat=1)) | ((pt < tpt2) & (threat=2));

// Rule balancing risk probability and balance parameters
// formula risk_policy = (pt < tpt1) | ((benefit > bt) & (pt < tpt2)) | (cost <= tct);

// Risk is demanded to an insurance
 formula risk_policy = true;


formula pt = threat=1 ? (tot1=0 ? 0.1 : (bad1/tot1)) :
            (threat=2 ? (tot2=0 ? 0.1 : (bad2/tot2)) : 0);

module KYCAML

x: [0..4] init 0; // module local state
bad1 : [0..n] init 0; 
bad2 : [0..n] init 0; 
tot1 : [0..n] init 0; 
tot2 : [0..n] init 0; 
insurance : bool init true;

[start] x=0 -> (x'=0);
[request] x=0 -> (x'=1);
[] x=1 & !(risk_policy) -> (x'=2);
[] x=1 & risk_policy & threat=1 -> pr1: (x'=3) & (bad1'=min(bad1+1,n)) & (tot1'=min(tot1+1,n)) +
                               (1-pr1): (x'=4) & (tot1'=min(tot1+1,n));
[] x=1 & risk_policy & threat=2 -> pr2: (x'=3) & (bad2'=min(bad2+1,n)) & (tot2'=min(tot2+1,n)) +
                               (1-pr2): (x'=4) & (tot2'=min(tot2+1,n));
[refuse] x=2 -> (x'=0);
[accept] x=3 | x=4 -> (x'=0);

endmodule

rewards "gain"
[accept] x=4 : benefit;
endrewards

rewards "insurance"
[accept] x=4 & insurance: insurance_cost;
endrewards

rewards "loss"
[accept] x=3 : insurance ? insurance_cost : cost;
[refuse] true : benefit;
endrewards

rewards "accepts"
[accept] true : 1;
endrewards

rewards "refuses"
[refuse] true : 1;
endrewards

rewards "incidents"
[accept] x=3 : 1;
endrewards

