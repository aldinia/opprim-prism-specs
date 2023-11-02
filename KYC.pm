dtmc

// maximum number of requests
const int n = 30;

// purchase cost 
const int a1 = 100;
const int a2 = 300;
// benefit
const int b1 = 15;
const int b2 = 60;

formula cost = (s=1) ? a1 : a2;    // cost of the purchase
formula benefit = (s=1) ? b1 : b2; // benefit of the purchase

module Buyer

s : [0..2] init 0;  // purchase type
req : [0..n] init 0; // requests counter
seller : [0..5] init 0; 
// Features of the five sellers:
// Seller 1: KYC = 0   incident_prob = 0.4
// Seller 2: KYC = 0.2 incident_prob = 0.3
// Seller 3: KYC = 0.4 incident_prob = 0.2
// Seller 4: KYC = 0.6 incident_prob = 0.1
// Seller 5: KYC = 0.8 incident_prob = 0.0

// choice of the purchase
[start] s=0 & req<n-> 0.5:(s'=1) + 0.5:(s'=2);
[] s=0 & req=n-> true;
// choice of the seller
[] s>0 & seller=0 -> 0.2:(seller'=1) + 0.2:(seller'=2) + 0.2:(seller'=3) + 0.2:(seller'=4) + 0.2:(seller'=5);

[request] s>0 & seller>0 -> (req'=min(req+1,n));
[accept]  s>0 & seller>0 -> (s'=0) & (seller'=0);
[refuse]  s>0 & seller>0 -> (s'=0) & (seller'=0);

endmodule


const int tct = 150;      // cost threshold
const int bt = 50;        // benefit threshold
const double tpt = 0.15;  // threat probability threshold
const double KYC;         // KYC threshold
const int insurance_fee;  // fixed cost of the insurance
const double value;       // used to estimate the incident probability

formula KYC_seller = max (0, (0.2 * seller) - 0.2);  // KYC of each seller
formula incident_prob = (0.5 - (seller * 0.10));     // Used when the incident probability depends on KYC
// formula incident_prob = value; // Used when the incident probability is an independent random variable 

// Rule taking into account only risk probability
// formula risk_policy = (pt < tpt);

// Rule balancing risk probability and balance parameters
// formula risk_policy = (pt < tpt) | ((benefit > bt) & (pt < (2 * tpt))) | (cost <= tct);

// No risk policy (used together with insurance)
// formula risk_policy = true;

// Rule based on KYC
formula risk_policy = KYC <= KYC_seller;

// Rule based on KYC + risk probability
// formula risk_policy = (KYC <= KYC_seller) & (pt < tpt);

// Rule based on KYC + risk probability and balance parameters
// formula risk_policy = (KYC <= KYC_seller) & ((pt < tpt) | ((benefit > bt) & (pt < (2 * tpt))) | (cost <= tct));

formula pt = (tot=0 ? 0.1 : (bad/tot));


module KYCAML

x: [0..4] init 0; // module local state
bad : [0..n] init 0; 
tot : [0..n] init 0; 
insurance : bool init false;
 
[start]   x=0 -> (x'=0);
[request] x=0 -> (x'=1); // start of the interaction

[] x=1 & !(risk_policy) -> (x'=2); // policy is not satisfied

[] x=1 & risk_policy ->     incident_prob: (x'=3) & (bad'=min(bad+1,n)) & (tot'=min(tot+1,n)) +
                        (1-incident_prob): (x'=4) & (tot'=min(tot+1,n));

[refuse] x=2 -> (x'=0);
[accept] x=3 | x=4 -> (x'=0);

endmodule

rewards "gain"
[accept] x=4 : benefit;
endrewards

// Insurance is paid whenever insurance is enabled and the rule does not hold 
rewards "insurance"
[accept] x=4 & insurance & KYC > KYC_seller: insurance_fee;
// [accept] x=4 & insurance & pt >= tpt: insurance_fee;
// [accept] x=4 & insurance & pt >= tpt & !((benefit > bt) & (pt < (2 * tpt))) & (cost > tct) : insurance_fee;
endrewards

// Insurance covers the loss if it has been paid
rewards "loss"
[accept] x=3 : (insurance & KYC > KYC_seller) ? 0 : cost;
// [accept] x=3 : (insurance & pt >= tpt) ? 0 : cost;
// [accept] x=3 : (insurance & pt >= tpt & !((benefit > bt) & (pt < (2 * tpt))) & (cost > tct)) ? 0 : cost;
// [refuse] true : benefit;
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

