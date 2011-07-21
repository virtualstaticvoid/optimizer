require(Rsolnp2)

factors <- c(
  0.02040000,-0.08672903,0.06208421,0.08537144,
  0.08530000,0.01567469,0.08519883,0.13293438,
  0.02570000,-0.03997748,0.04657237,0.04977169,
  0.00760000,0.04163002,-0.00568537,-0.02547824,
  0.04540000,0.11255746,0.05319682,0.04129890,
  -0.01830000,0.00805313,-0.00421743,-0.05443995,
  -0.03520000,-0.08656963,-0.05054419,-0.01769600,
  0.07920000,0.16539408,0.05479713,0.06737632,
  0.03190000,0.02451794,0.02632593,0.01820807,
  0.07870000,0.05045111,0.07801389,0.09820405,
  0.02140000,0.02911620,0.00553052,0.03437993,
  0.08920000,0.16132008,0.09959438,0.09472788,
  -0.02850000,-0.02864671,-0.03634867,-0.04231819,
  0.02810000,0.02976673,0.03965725,0.04903749,
  0.08810000,0.07181523,0.07879099,0.06418204,
  0.09070000,0.11896197,0.07516213,0.11833781,
  -0.02310000,-0.07499952,-0.00807299,-0.02992491,
  0.06940000,0.09002753,0.09137129,0.09216098,
  0.02640000,0.08124712,0.02024337,0.02541702,
  -0.04460000,0.01855777,-0.04992867,-0.04843952,
  0.01530000,0.10141779,0.02720172,0.05258464,
  -0.00860000,-0.04908988,-0.00546264,-0.03273162,
  0.05120000,0.05606888,0.08323532,0.08211691,
  0.02090000,0.00249315,0.02060449,-0.00069403,
  0.05400000,0.03418127,0.05196274,0.04239199
)

factors <- matrix(data=factors, nrow=25, ncol=4, byrow=TRUE)

fund_returns <- c(
  0.07950000,
  0.11440000,
  0.04550000,
  0.01010000,
  0.03350000,
  -0.01470000,
  -0.02160000,
  0.07120000,
  0.02200000,
  0.08970000,
  0.02530000,
  0.04560000,
  -0.01980000,
  0.03100000,
  0.06020000,
  0.08530000,
  0.00640000,
  0.05500000,
  0.02920000,
  -0.02150000,
  0.00160000,
  0.00830000,
  0.04780000,
  0.02280000,
  0.04110000  
)

objective <- function(weights) {

   # ASSERT: ncol(factors) == length(weights)
   
   # calculate the sum product of factors and weights
   #  (there is probably a better way to do this in R (but me not knows how)... a one liner I suspect :)
   residuals <- rep(c(0), nrow(factors))
   for(i in 1:nrow(factors))
   {
     t <- 0
     for(j in 1:ncol(factors))
     {
       t <- t + (factors[i, j] * weights[j])
     }
     # calculate the residual
     residuals[i] <- t - fund_returns[i]
   }
 
   # calculate (and return) the stdev of the residuals
   sd(residuals)

}

weights <- c(0.25, 0.25, 0.25, 0.25)   # start weights

# weight constraints
weights.lower <- c(0, 0, 0, 0)         # >= 0
weights.upper <- c(1, 1, 1, 1)         # <= 1

# equality constraints
eqFun <- list(
  function(x) sum(x)
)
eqFun.bound <- c(1)

# note: no need for inequality and non-linear constraints

x1 <- solnp2NLP( 
  par = weights,
  par.lower = weights.lower,
  par.upper = weights.upper,
  fun = objective,
  eqFun = eqFun,
  eqFun.bound = eqFun.bound
)

#str(x1)

found_weights = x1$par

# sanity check
if (sum(found_weights) > 1.00000000000001 || sum(found_weights) < 1) 
 cat('FAILED: Sum(W) = ', sum(found_weights), '\n')

if (sum(abs(found_weights)) > 1.00000000000001 || sum(abs(found_weights)) < 1) 
 cat('FAILED: Sum(Abs(W)) = ', sum(abs(found_weights)), '\n')

if(any(found_weights < 0) || any(found_weights > 1))
  cat('FAILED: One or more factor weight <0 or >1\n')

# print out weights....
cat(found_weights[1], '\t', found_weights[2],'\t', found_weights[3],'\t', found_weights[4], '\n')

