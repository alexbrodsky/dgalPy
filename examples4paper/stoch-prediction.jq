
// update of figure 14
// declare function ns:stochOrderAnalytics($purchase_and_demand) ...
// ...
let $totalCost := ....
// ...
let $withinBudget as boolean := $totalCost <= 3000
let $constraints as boolean := $supplyAvailability && $demandSatisfied && $withinBudget

// in the return structure add key-value pair
// withinBudget: $withinBudget

// ----------------------------------------------------------------------------------
//update of figure 16

//  replace object of this form { expectation: 3.8, stddeviation: 0.09} to
// { mean: 3.8, sigma: 0.09}

// the value for withinBudget and for constraints will be of the form
// { value: TRUE, prob: 0.93 }

//-------------------------------------------------------------------------------------
// update of figure 15
//...

return predict({
  model: $AM,
  input: ...,
  config: { sigmaRatioBound: 0.05 ,timeBound: 120.0 }

  })

return minimize({
  model: $AM,
  input: ...,
  objective: function($o){return $o.orderCost},
  constraints: {path: function($o){return $o.constraint}, lb: 0.95 },
  config: { confidence: 0.99  , timeBound: 3600.0}
  })
//----------------------------------------------------------------
