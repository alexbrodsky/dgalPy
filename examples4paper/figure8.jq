// ...
// let $varInput = ...


// declare function ns:obj($o) as object {
//   return $o.orderCost
// }
// declare function ns:constraints($o) as Boolean {
//   return $o.constraints
//}
let $AM := sp:orderAnalytics#1
// let $obj := ns:obj#1
// let $constraints := ns:constraints#1

//return minimize({model: $AM, input: $varInput, objective: $obj, constraints: $constraints})

// alternative

return minimize({model: $AM,
                input: $varInput,
                objective: function($o){$o.orderCost},
                constraints: function($o){$o.constraints}
})
