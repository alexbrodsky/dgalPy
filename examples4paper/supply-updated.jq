module namespace ns := "www.gmu.edu/~brodsky/composableSupplychain"
declare variable $exampleCompositeInput :=
{   id: "mySupplyChain",
    type: "composite",
    input: [],
    output: ["prod1", "prod2"],
    inputQty: { },
    outputQty: { prod1: 50, prod2: 100 },
    subProcesses: [ "combinedSupply", "combinedManuf" ]
},
{   id: "combinedSupply",
    type: "composite",
    input: [],
    output: ["mat1","mat2"],
    inputQty: { },
    outputQty: { mat1: 500, mat2: 200 },
    subProcesses: [ "supp1", "supp2" ]
},
{   id: "combinedManuf"
    type: "composite",
    input: ["mat1","mat2"],
    output: ["prod1","prod2"],
    inputQty: { mat1: 500, mat2: 200 },
    outputQty: { prod1: 50, prod2: 100 },
    subProcesses: [ "tier1manuf", "tier2manuf" ]
},
{   id: "supp1",
    type: "supplier",
    input: [],
    output: ["mat1","mat2"],
    inputQty: { },
    outputQty: { mat1 : 10, mat2: 20 },
    ppu: {mat1: 5.0, mat2: 3.0 }
},
{   id: "supp2",
    type: "supplier",
    input: [],
    output: ["mat1","mat2"],
    inputQty: { },
    outputQty: { "mat1": 20, "mat2": 5 },
    ppu: {mat1: 4.0, mat2: 5.0 }
},
{   id: "tier1manuf",
    type: "manufacturer",
    input: ["mat1","mat2"],
    output: ["part1","part2"],
    outputQty: { part1: 40, part2: 60 },
    inQtyPer1out: [
        { key : {out:"part1", in:"mat1"}, qty: 2 },
        { key : {out: "part1", in: "mat2"}, qty: 1 },
        { key : {out: "part2", in: "mat2"}, qty: 3 }
    ],
    manufCostPerUnit: [ { part1: 30.0}, {part2: 20.0} ]
},
{   id: "tier12manuf",
    type: "manufacturer",
(: note, inputQty not given, will be computed :)
    input: ["part1","part2"],
    output: ["prod1","prod2"],
    outputQty: { prod1: 30, prod2: 70 },

    inQtyPer1out: [
        { key : {out: "prod1", in: "part1"}, qty: 2 },
        { key : {out: "prod1", in: "part2"}, qty: 1 },
        { key : {out: "prod2", in: "part2"}, qty: 3 }
    ],
    manufCostPerUnit: [ { part1: 30.0}, {part2: 20.0} ]
},

//----------------------------------------------------------------

declare variable $exampleCompositeOutput :=

{   id: "mySupplyChain",
    type: "composite",
    cost: 2000.0,
    constraints: false,
    input: [],
    output: ["prod1", "prod2"],
    inputQty: { },
    outputQty: { prod1: 50, prod2: 100 },
    subProcesses: [ "combinedSupply", "combinedManuf" ]
},
{   id: "combinedSupply",
    type: "composite",
    cost: 800.0,
    constraints: true,
    input: [],
    output: ["mat1","mat2"],
    inputQty: { },
    outputQty: { mat1: 500, mat2: 200 },
    subProcesses: [ "supp1", "supp2" ]
},
{   id: "combinedManuf"
    type: "composite",
    cost: 1200.0,
    constraints: false,
    input: ["mat1","mat2"],
    output: ["prod1","prod2"],
    inputQty: { mat1: 500, mat2: 200 },
    outputQty: { prod1: 50, prod2: 100 },
    subProcesses: [ "tier1manuf", "tier2manuf" ]
},
{   id: "supp1",
    type: "supplier",
    cost: 1120.0,
    constraints: true,
    input: [],
    output: ["mat1","mat2"],
    inputQty: { },
    outputQty: { mat1 : 10, mat2: 20 },
    ppu: {mat1: 5.0, mat2: 3.0 }
},
{   id: "supp2",
    type: "supplier",
    cost: 500.0,
    constraints: true,
    input: [],
    output: ["mat1","mat2"],
    inputQty: { },
    outputQty: { "mat1": 20, "mat2": 5 },
    ppu: {mat1: 4.0, mat2: 5.0 }
},
{   id: "tier1manuf",
    type: "manufacturer",
    cost: 2000.0,
    constraints: true,
    input: ["mat1","mat2"],
    output: ["part1","part2"],
    inputQty: { mat1: 50, mat2: 40 },
    outputQty: { part1: 40, part2: 60 },
    inQtyPer1out: [
        { key : {out:"part1", in:"mat1"}, qty: 2 },
        { key : {out: "part1", in: "mat2"}, qty: 1 },
        { key : {out: "part2", in: "mat2"}, qty: 3 }
    ],
    manufCostPerUnit: { part1: 30.0, part2: 20.0}
},
{   id: "tier12manuf",
    type: "manufacturer",
    cost: 700.0,
    constraints: true,
    input: ["part1","part2"],
    output: ["prod1","prod2"],
    inputQty: {part1: 50, part2: 30 },
    outputQty: { prod1: 30, prod2: 70 },

    inQtyPer1out: [
        { key : {out: "prod1", in: "part1"}, qty: 2 },
        { key : {out: "prod1", in: "part2"}, qty: 1 },
        { key : {out: "prod2", in: "part2"}, qty: 3 }
    ],
    manufCostPerUnit: { part1: 30.0, part2: 20.0}
},


(: input schema :)
(: output schema :)

declare function ns:supplierMetrics($suppInput) {
let
    $cost := sum (for $i in $suppInput.output return ($suppInput.ppu.$i * $suppInput.outputQty.$i)),
    $suppOutput := $suppInput,
    $suppOutput.cost := $cost,
    $suppOutput.constraints := true
return $suppOutput
}

(: -----------------------------------------:)

declare function ns:manufMetrics($manufInput) {
let
    $cost := sum (for $o in $manufInput.output return ($manufInput.manufCostPerUnit.$o * $manufInput.outputQty.$o),
    $inputQty := {|
        for $i in $manufInput.input
        let $qty := sum (for $ipo in $manufInput.inQtyPer1out where $ipo.key.in = $i return ($ipo.qty * $manufInput.outputQty.($ipo.key.out))
        return { $i:$qty }
    |},
    $constraints := true
    $manufOutput := manufInput,
    $manufOutput.cost := $cost,
    $manufOutput.constraints := $constraints,
    $manufOutput.inputQty := $inputQty
return
    $manufOuput
}
-----------------------


declare function ns:scMetrics($scInput as object) {
// $scInput is of the form {kb: inputKB, root: inputRoot}

let $rootProcess := $scInput.kb[id = $scInput.root];
let $rootType: $rootProcess.type;
let $processMetrics :=
   if ($rootType = "supplier")          then ns:supplierMetrics($rootProcess)
   else if ($rootType = "manufacturer"      then ns:manufMetrics($rootProcess)
   else if ($rootType = "composite"         then
    (
    let
    $SubProcessMetrics := (
        for $p in $rootProcess.subProcesses
        return ns:scMetrics({kb: $scInput.kb, root: $p}
    ),
    $FirstLevelSubProcesses := for $p in $rootProcess.subProcesses return $SubProcessMetrics[id = $p],
    $cost := sum (for $p in $FirstLevelSubProcesses return $p.cost),
    $subProcessConstraints := every $p in $FirstLevelSubProcesses satisfies $p.constraints,
    $ProcessItems :=  distinct-values(
                    $rootProcess.input,
                    $rootProcess.output,
                    (for $p in $FirstLevelSubProcesses return ($p.input, $p.output))
                ),
    $zeroSumConstraints :=  every $i in $ProcessItems
                    satisfies (
                        let $itemSupply :=
                            $rootProcess.inputQty.$i +
                            sum (for $p in $FirstLevelSubProcesses return $p.outputQty.$i),

                        let $itemDemand :=
                            $rootProcess.outputQty.$i +
                            sum (for $p in $FirstLevelSubProcesses return $p.inputQty.$i),
                        return ($itemSupply = $itemDemand)
                    ),
    $constraints := $subProcessConstraints and $zeroSumConstraints,
    $rootProcessMetrics := $rootProcess,
    $rootProcessMetrics.cost := $cost,
    $rootProcessMetrics.constraints := $constraints
    return $rootProcessMetrics
    )
return $processMetrics
}






collection("suppliersCatalog"):
    {supplier : "s1",
     itemPrices : [ {item :  "i1", ppu: 1.0 },
                    {item : "i2", ppu: 2.9}, {item :  "i3", ppu: 4.5}] ,
     volumeDiscOver : 200.0,
     volumeDiscRate : 0.05
     },
    {supplier :  "s2",
     itemPrices: [ {item : "i1", ppu: 2.0},
                   {item : "i2", ppu: 3.2},  {item : "i3", ppu:  4.3} ],
     volumeDiscOver : 100.0,
     volumeDiscRate : 0.2
    },


  collection("supplierOrders"):
    {supplier:"s1", item:"i1", qty:100},
    {supplier:"s1", item:"i2", qty:50}
    {supplier:"s2", item:"i1", qty:20},
    {supplier:"s2", item:"i2", qty:200},
    {supplier:"s2", item:"i3", qty:300}
   },


  collection("supplierOrdersReport"):
   { budget : 2000.0,
     ordersDetail:[
       {supplier: "s1",
        supplierItems: [{ item:"i1", ppu:1.0, qty:100, itemCost:100.0 },
                        { item:"i2", ppu:2.9, qty:0, itemCost: 0.0 },
                        { item:"i3", ppu: 4.5, qty:0, itemCost: 0.0}
                        ],
        costBeforeDisc: 100.0,
        cost:100.0
       },
       {supplier: "s2",
        supplierItems: [{item:"i1", ppu: 2.0, qty: 0, itemCost: 0.0 },
                        {item:"i2", ppu: 3.2, qty: 200, itemCost: 640.0},
                        {item:"i3", ppu: 4.3, qty: 300, itemCost: 1290.0}
                        ],
        costBeforeDisc: 1930.0,
        cost:1564.0
       }]
     demandSatisfied:true,
     totalCost:1664.0,
     withinBudget:true,
   }


 declare variable $local:supplierInvoices:= {
   let   $suppliers := collection("suppliersCatalog"),
         $demand := collection("itemsDemand"),
         $orders := collection("supplierOrders_1"),
         $budget as decimal := 2000.0,

   $ordersDetail := [
    for $s in $suppliers let
    $itemQtys := [
        for $i in $s.itemPrices[] let
        $qty as integer := $orders[$$.supplier = $s.supplier && $$.item = $i.item].qty,
            $itemCost := $i.ppu * $qty
        return {item : $i.item, ppu : $i.ppu, qty : $qty, itemCost : $itemCost }
    ],
    $costBeforeDisc := sum (for $i in $itemQtys[] return $i.itemCost),
    $cost :=
    if ($costBeforeDisc <= $s.volumeDiscOver)
    then $costBeforeDisc
    else $s.volumeDiscOver + ($costBeforeDisc - $s.volumeDiscOver) * (1.0 - $s.volumeDiscRate)

    return {
        supplier : $s.supplier,
        itemQtys : $itemQtys,
        costBeforeDisc : $costBeforeDisc,
        cost : $cost
        }
   ],

  $demandSatisfied as boolean :=
    every $d in $demand satisfies
        $d.qty =  sum (for $i in $ordersDetail[].itemQtys[] where $i.item = $d.item return
                $i.qty),
  $totalCost := sum (for $od in $ordersDetail[] return
            $od.cost),
  $withinBudget as boolean := ($totalCost <= $budget)
  return {
    budget: $budget,
    ordersDetail: $ordersDetail,
    demandSatisfied: $demandSatisfied,
    totalCost: $totalCost,
    withinBudget: $withinBudget
    }
  };

  {supplierOrdersReport_1: $local:supplierInvoices}​




    // $myCost := $qty(suppItem,"ibm","ibm_service");
    // $myCost := index($suppItem,$qty,"ibm","ibm_service");

   declare variable $local:supplierInvoices:= { let
    $suppliers := …,
    $demand := …,
    // Note, no $orders as a collection now
    $budget as decimal := ?,

    $ordersDetail := [
      for $s in $suppliers let
       $itemQtys := [
       for $i in $s.itemPrices[]
          index $suppItem { supplier: $s.supplier, item: $i.item }
                                       // defines a set of tuples
          let $qty($suppItem) as integer := ?,
                $itemCost($suppItem) := $i.ppu * $qty
       return {item : $i.item, ppu : $i.ppu, qty : $qty, itemCost : $itemCost }
       ],
      $costBeforeDisc := sum (for $i in $itemQtys[] return $i.itemCost),
      $myCost as integer := $qty(suppItem, "ibm", "ibm_service"); // check syntax

      $cost:= if ($costBeforeDisc <= $s.volumeDiscOver)
               then $costBeforeDisc
               else $s.volumeDiscOver+($costBeforeDisc-$s.volumeDiscOver)*(1.0 -$s.volumeDiscRate)
     return {
        supplier : $s.supplier,
        itemQtys : $itemQtys,
        costBeforeDisc : $costBeforeDisc,
        cost : $cost
      }
    ],
  $demandSatisfied as constraint := every $d in $demand satisfies
        $d.qty = sum (for $i in $ordersDetail[].itemQtys[] where $i.item = $d.item
                return $i.qty ),
  $totalCost := sum (for $od in $ordersDetail[]
                return $od.cost ),
  $withinBudget as constraint := ($totalCost <= $budget)
  return {
    budget: $budget,
    ordersDetail: $ordersDetail,
    demandSatisfied: $demandSatisfied,
    totalCost: $totalCost,
    withinBudget: $withinBudget
    }
  };


  //-----------------------------------
  // usage of the previous:
  // computation:
  let $my_purchase := $local:supplierInvoices {
                $suppliers := collection("suppliersCatalog"),
                $demand := collection("itemsDemand"),
                $budget := 20000,
                $suppItem := collection("supplierOrders_1")
  },

  { computed_invoice: compute($my_purchase) }




   // optimization:
   let parameterized_purchase := $local:supplierInvoices {
                         $suppliers := collection("suppliersCatalog"),
                         $demand := collection("itemsDemand"),
                         $budget := 2000
   },

   { optimized_invoice: minimize({ao: $parameterized_purchase, objective: "totalCost"})}


   // learning:

   let $supplierItems := [ {supplier: "s1", items: ["i1", "i2"], volumeDiscOver:200.0},
                           {supplier: "s2", items: ["i1", "i2", "i3"], volumeDiscOver:100.0}]
   let $pricesUknownInvoice := $local:supplierInvoices{
               $suppliers := [ for $si in $supplierItems let
                                 $supplier := $si.supplier,
                                 $itemPrices := [
                                    for $i in $si.items let $item := $si.item,
                                                            $ppu as float := ?
                                      return {item: $item, ppu:$ppu}
                                 ]
                               $volumeDiscOver := $si.volumeDiscOver,
                               $volumeDiscRate as float := ?
                               return {supplier: $supplier, itemPrices: $itemPrices,
                                                  volumeDiscOver: $volumeDiscOver,
                                                  volumeDiscRate:$volumeDiscRate}
                              ],
               $demand := collection("itemsDemand"),
               $budget := 20000 }
   let $learningSet := [{input: $pricesUnknownInvoice
                         {$suppItem := collection("supplier_orders1"), totalCost: 1500.0},
                        {input: $pricesUnknownInvoice
                           {$suppItem := collection("supplier_orders2"), totalCost: 1768.0},
                         {input: $pricesUnknownInvoice
                           {$suppItem := collection("supplier_orders3"), totalCost: 1500.0},
                ….
                ]
   {learnedParamsInvoice: learn({ ao: $pricesUknownInvoice, learningSet: $learningSet})}


  ///////////////////////////////////////////////////////

  //------------------------------------------------------------
// computation example with extended JSONiq

let
$suppItems := collection("supplierItems"),
$demand := collection("itemsDemand"),
$suppDiscounts := collection("supplierDiscounts"),
$suppOrders := collection("supplierOrders"),
$budget := 2000,
$ordersDetail := [
    for $s in $suppItems let
    $items := [
        for $i in $s.items[] let
        $suppItem as index := { supplier: $s.supplier, item: $i.item },
        $ppu($suppItem) as float := $suppOrders[$$.supplier =
                                $suppItem.supplier && $$.item = $suppItem.item].ppu,
        $qty($suppItem) as integer := $suppOrders[$$.supplier = $suppItem.supplier
                                                    && $$.item = $suppItem.item].qty,
            $itemCost($suppItem) := $ppu($suppItem) * $qty($suppItem)
        return {item : $i.item, ppu : $ppu($suppItem), qty : $qty($suppItem),
                                                    itemCost : $itemCost($suppItem) }
    ],
    $supp as index := {supplier: $s.supplier},
    $costBeforeDisc($supp) := sum (for $suppItem in $indexSuppItem where
                            $suppItem.supplier = $supp.supplier) $itemCost($suppItem),
    $volDiscBound($supp) as float := $suppDiscounts[$$.supplier = $supp.supplier].volDiscBound,
    $volDiscRate($supp) as float := $suppDiscounts[$$.supplier = $supp.supplier].volDiscRate,
    $cost($supp) as float := if ($costBeforeDisc($supp) <= $volDiscBound($supp)
                     then $costBeforeDisc($supp)
                     else $volDiscBound($supp) + ($costBeforeDisc($supp) - $volDiscBound($supp))
                                                                   * (1.0 - $volDiscRate($supp))
    return { supplier : $s.supplier, itemQtys : $itemQtys, costBeforeDisc :
                                                                 $costBeforeDisc, cost : $cost }
],
$demandSatisfied as constraint  :=
  every ( $d in $demand let
           $demItem as index := {demItem: $d.item},
           $demQty($demItem) as integer := $d.qty
           )
  satisfies $demQty($demItem) <= sum (for $si in indexSuppItem where $si.item = $d.item)$qty($si)

$totalCost as float := sum ($s in $suppliers) $cost({supplier: $s.supplier}),
$withinBudget as constraint := ($totalCost <= $budget)
return {
    budget: $budget,
    ordersDetail: $ordersDetail,
    demandSatisfied: $demandSatisfied,
    totalCost: $totalCost,
    withinBudget: $withinBudget
}};


//------------------------------------------------------------

//  an example of AO used for computation, optimization, learning

module namespace ns:= "www.gmu.edu/~brodsky/dgal_suppliers_example" {

declare variable $ns:supplierInvoices as aObject := { let

$suppItems as json := …,
$demand as json := …,
$budget as decimal := ?,

$ordersDetail := [
    for $s in $suppItems let
    $items := [
        for $i in $s.items[] let
        $suppItem as index := { supplier: $s.supplier, item: $i.item },
        $ppu($suppItem) as float := …,
        $qty($suppItem) as integer := ?,
            $itemCost($suppItem) := $ppu($suppItem) * $qty($suppItem)
        return {item : $i.item, ppu : $ppu($suppItem), qty : $qty($suppItem),
                                              itemCost : $itemCost($suppItem) }
    ],
    $supp as index := {supplier: $s.supplier},
    $costBeforeDisc($supp) := sum (for $suppItem in $indexSuppItem where
                       $suppItem.supplier = $supp.supplier) $itemCost($suppItem),
    $volDiscBound($supp) as float := …,
    $volDiscRate($supp) as float := …,
    $cost($supp) as float := if ($costBeforeDisc($supp) <= $volDiscBound($supp)
                     then $costBeforeDisc($supp)
                     else $volDiscBound($supp) + ($costBeforeDisc($supp) -
                             $volDiscBound($supp)) * (1.0 - $volDiscRate($supp))
    return { supplier : $s.supplier, itemQtys : $itemQtys,
                                  costBeforeDisc : $costBeforeDisc, cost : $cost }
],

$demandSatisfied as constraint  :=
    every ( $d in $demand let
            $demItem as index := {demItem: $d.item},
            $demQty($demItem) as integer := $d.qty
            )
    satisfies $demQty($demItem) = sum (for $si in $indexSuppItem where $si.item
                                                               = $d.item) $qty($si)

$totalCost as float := sum ($s in $suppliers) $cost({supplier: $s.supplier}),
$withinBudget as constraint := ($totalCost <= $budget)

return {
    budget: $budget,
    ordersDetail: $ordersDetail,
    demandSatisfied: $demandSatisfied,
    totalCost: $totalCost,
    withinBudget: $withinBudget

}}};


// note: implicitely created global vars: $suppItemIndex, $suppItem…?Values, $suppItem…Values, $suppItem?Values,
//       $suppIndex, $supp…?Values, $supp…Values, $supp?Values

//-----------------------------------
// usage of the previous:

import module namespace su = "www.gmu.edu/~brodsky/dgal_suppliers_example";
// ---- computation:
let $instantiatedPurchase := $su:supplierInvoices {
                $suppItems := collection("supplierItems"),
                $demand := collection("itemsDemand"),
                $budget := 2000,
                $suppItem…?Values := collection("supplierOrders"),
                $supp…Values := collection("supplierDiscounts")
},
{ computed_invoice: compute($instantiatedPurchase) }

// ---- optimization:
let $purchaseWithVarQtys := $su:supplierInvoices {
                        $suppItems := collection("supplierItems"),
                        $demand := collection("itemsDemand"),
                        $budget := 2000,
                        // note: $qty($suppItemIndex) is now NOT instantiated
                        $suppItem…Values := collection("supplierItemPrices"),

                        $supp…Values := collection("supplierDiscounts")},

{ optimized_invoice: minimize({aObject: $local:parameterized_purchase,
                                                  objective: "totalCost"})}

// learning:
let $invoiceWithVolDiscounts := $su:supplierInvoice{ $supp…Values :=
                                              collection("supplierDiscounts")},
let $learningSet := [{input: $invoiceWithVolDiscounts{
                           $suppItem?qty := collection("supplierItemQtys_1")}, totalCost: 1500.0},
                {input: $invoiceWithVolDiscounts{
                           $suppItem?qty := collection("supplierItemQtys_2")}, totalCost: 367.0},
                {input: $invoiceWithVolDiscounts{
                           $suppItem?qty := collection("supplierItemQtys_3")}, totalCost: 2560.0},
                ...   ...
]
{ learnedParamsInvoice: learn({ aObject: $invoiceWithVolDiscounts, learningSet: $learningSet}) }




//--------------------------------------------
// needs added uncertainty
// example of AO with uncertainty

declare variable $suppUncertainInvoices as aObject := { let

$suppItems as json := …,
$demand as json := …,
$budget as decimal := ?,

$ordersDetail := [
  for $s in $suppItems let
   $items := [
     for $i in $s.items[] let
      $suppItem as index := { supplier: $s.supplier, item: $i.item },
      $ppuExp($suppItem) as float := …,
      $ppu($suppItem) as float := $ppuExp($suppItem)+Gaussian(0, $ppuExp($suppItem) * 0.05),
      $qty($suppItem) as integer := ?,
        $itemCost($suppItem) := $ppu($suppItem) * $qty($suppItem)
      return {item : $i.item, expPpu : exp($ppu($suppItem)), qty : $qty($suppItem),
                                                  expItemCost : exp($itemCost($suppItem)) }
   ],
   $supp as index := {supplier: $s.supplier},
   $costBeforeDisc($supp) := sum (for $suppItem in $indexSuppItem
                            where $suppItem.supplier = $supp.supplier) $itemCost($suppItem),
   $volDiscBound($supp) as float := …,
   $volDiscRateExp($supp) as float := …,
   $volDiscRate($supp) as float := $volDiscRateExp($supp) +
                                                  Gaussian(0, $volDiscRateExp($supp) * 0.02)
   $cost($supp) as float := if ($costBeforeDisc($supp) <= $volDiscBound($supp)
                     then $costBeforeDisc($supp)
                     else $volDiscBound($supp) + ($costBeforeDisc($supp) -
                                         $volDiscBound($supp)) * (1.0 - $volDiscRate($supp))
    return { supplier : $s.supplier, itemQtys : $items,
                            expCostBeforeDisc : exp($costBeforeDisc), expCost : exp($cost) }
],
$demandSatisfied as constraint  :=
  every ( $d in $demand let
           $demItem as index := {demItem: $d.item},
           $demQty($demItem) as integer := $d.qty
        )
 satisfies $demQty($demItem)=sum(for $si in indexSuppItem where $si.item = $d.item) $qty($si)

$totalCost as float := sum ($s in $suppliers) $cost({supplier: $s.supplier}),

$withinBudget as constraint := Probability ($totalCost <= $budget) with probability >= 0.95
                                                                  with confidence level 0.99,
return {
    budget: $budget,
    ordersDetail: $ordersDetail,
    demandSatisfied: $demandSatisfied,
    totalExpCost: $totalExpCost,
    withinBudget: $withinBudget

}};

//-----------------------------------------------

// --Example of DGAL module w/AOs and typing

declare $ns:supplierOrders :=
//modify supplier invoices to use the computation from the JSONiq example??


module namespace ns:= "www.gmu.edu/~brodsky/dgal_suppliers_example" {
declare $ns:itemPrice := { let
    $item as string := ...;
    $ppu as float := ...;
    $nonNegativePpu as constraint := $ppu >= 0.0;
    return ($item, $ppu)
    };
declare $ns:supplier := {   let
    $supplier as string : = ...;
    $itemPrices as [$ns:itemPrice*] := ...;
    $volumeDiscOver as float := ...;
    $volumeDiscRate as float := ...;
    };
declare $ns:itemQty := { let
    $item as string := ...;
    $qty as int := ?;
    $nonNegativeQty as constraint := qty >= 0;
    return ($item, $qty)
};
declare $ns:supplierInvoices :=  {
    $suppliers as [$ns:supplier*] := ...;
    $demand as [$ns:itemQty*] := ...;
    $budget as float := ?;

    $supplierOrders := [
          for $s in $suppliers
              return {
            $supplier := $s.supplier,
            $itemQtys := [
            for $i in $s.itemPrices
            return {
                $item := $i.item,
                $ppu := $i.ppu,
                $qty as int := ?,
                $itemCost as float := $ppu * $qty,
                }
            ],

            $costBeforeDisc := sum ($j in $itemQtys) $j.itemCost,
            $cost := if ($costBeforeDisc <= $s.volumeDiscOver)
                       then $costBeforeDisc
                     else $s.volumeDiscOver +
                       ($costBeforeDisc - $s.volumeDiscOver) * (1.0 - $s.volumeDiscRate),
              }
    ]

    let $suppItemIndex  as index($s,$i) :=
        $supplierOrders[][$$.supplier = $s].itemQtys[][$$.item = $i],
        $demandSatisfied as constraint := forall ($d in $demand)
           $d.qty == sum ($s in $supplierOrders[] ) $suppItemIndex($s.supplier,$d.item).qty;

        $totalCost as float := sum ($so in $supplierOrders) $so.cost;
        $withinBudget as constraint := $totalCost <= $budget;
    };
}



/////////////////

collection("itemsDemand"):
   {item: "i1", qty: 120},
   {item: "i2", qty: 250},
   {item: "i3", qty: 350}

collection("supplierItems"):
   {supplier : "s1", items : [ "i1", "i2", "i3"] },
   {supplier : "s2", items : [ "i1", "i2", "i3"] }

collection("supplierOrders"):
   {supplier: "s1", item : "i1", ppu: 1.0, qty: 100},
   {supplier: "s1", item : "i2", ppu: 2.9, qty: 50},
   {supplier: "s2", item : "i1", ppu: 2.0, qty: 20},
   {supplier: "s2", item : "i2", ppu: 3.2, qty: 200},
   {supplier: "s2", item : "i3", ppu: 4.3, qty: 300}

collection("supplierDiscounts"):
   {supplier: "s1", volumeDiscOver : 200.0, volumeDiscRate : 0.05},
   {supplier: "s2", volumeDiscOver : 100.0, volumeDiscRate : 0.2}



   ====================New DGAL Design  ICEIS 2015  =======================================
   // Figure 3

collection("demand1.jsn"):
    {item: 1, demQty: 100},
    {item: 2, demQty: 500},
    {item: 3, demQty: 130},
    {item: 4, demQty: 50}

collection("purchase1.jsn"):
    {  sup: 15,
        volumeDiscOver: 200,
        volumeDiscRate: 0.05,
        items: [
            { item:1, ppu: 2.0, availQty: 70, qty: 150 },
            { item:2, ppu: 7.5, availQty: 2000, qty: 100 }
        ],
    },
    {  sup: 17,
        volumeDiscOver: 100,
        volumeDiscRate: 0.10,
        items: [
            {item: 1, ppu: 3.8, availQty: 2500, qty: 10 },
            {item: 3, ppu: 3.5, availQty: 5000, qty: 130 },
            {item: 4, ppu: 3.5, availQty: 50,   qty: 200 }
        ]
    },
    {  sup: 19,
        volumeDiscOver: 200,
        volumeDiscRate: 0.15,
        items: [
            {item: 2, ppu: 6.8, availQty: 1000, qty: 35 }
        ]
    }

collection("demandAndPurchase"):
{ demand: [ {item: 1, demQty: 100},
            {item: 2, demQty: 500},
            {item: 3, demQty: 130},
            {item: 4, demQty: 50} ]
purchase: [ {  sup: 15,
               volumeDiscOver: 200,
               volumeDiscRate: 0.05,
               items: [
                  { item:1, ppu: 2.0, availQty: 70, qty: 150 },
                  { item:2, ppu: 7.5, availQty: 2000, qty: 100 } ]
              {  sup: 17,
                 volumeDiscOver: 100,
                 volumeDiscRate: 0.10,
                 items: [
                    {item: 1, ppu: 3.8, availQty: 2500, qty: 10 },
                    {item: 3, ppu: 3.5, availQty: 5000, qty: 130 },
                     {item: 4, ppu: 3.5, availQty: 50,   qty: 200 } ]
              },
              {  sup: 19,
                 volumeDiscOver: 200,
                 volumeDiscRate: 0.15,
                  items: [
                        {item: 2, ppu: 6.8, availQty: 1000, qty: 35 }
                ]
              }

]}
}



}

// Figure 4


module namespace ns:= "www.gmu.edu/~brodsky/jsoniq_dga_example"
declare function ns:orderAnalytics($purchase_and_demand) as object { let
$supInfo := $purchase_and_demand.purchase[]
$suppliers := $supInfo[].sup
$orderedItems := $purchase_and_demand.demand[]

let $perSup := [
  for $s in $suppliers
    let $priceBeforeDisc := sum ( for $si in $supInfo, $i in $s.items[]
                                    where $si.sup = $s
                                    return $i.ppu * $i.qty
    )
    let $priceAfterDisc := (   let $bound := $s.volumeDiscOver
                 let $disc  := $s.volumeDiscRate
                 return  if $priceBeforeDisc <= $bound
                      then $priceBeforeDiscount
                      else $bound + ($priceBeforeDiscount - $bound) * $disc
    )
    return {sup:$s, items:$s.items,
                   priceBeforeDisc: $priceBeforeDisc, price:$priceAfterDisc}
]
let $totalCost := sum (for $s in $perSup[] return $s.price)
let $supAvailability as boolean :=
    every $i in $supInfo[].items[] satisfies $i.qty <= $i.availQty
let $demandSatisfied as boolean :=
    every ( $i in $orderedItems.item
            let $supQty := sum ($it in $supInfo[].items[]
                                    where $it.item = $i
                                    return $it.qty)
    )
    satisfies $i.demQty <= $supQty
let $constraints as boolean := $supAvailability && $demandSatisfied
return {
    demand: [$orderedItems],
    perSup: $perSup,
    orderCost: $totalCost,
    demandSatisfied: $demandSatisfied,
    supplyAvailability: $supAvailability,
    constraints: $constraints
    }
}


module namespace ns:= "www.gmu.edu/~brodsky/jsoniq_dga_example"
declare function ns:orderAnalytics($purchase_and_demand) as object { let
$supInfo := $purchase_and_demand.purchase[]
$suppliers := $supInfo[].sup
$orderedItems := $purchase_and_demand.demand[]

let $perSup := [
  for $s in $suppliers
    let $priceBeforeDisc := sum ( for $si in $supInfo, $i in $s.items[]
                                    where $si.sup = $s
                                    return $i.ppu * $i.qty
    )
    let $priceAfterDisc := (   let $bound := $s.volumeDiscOver
                 let $disc  := $s.volumeDiscRate
                 return  if $priceBeforeDisc <= $bound
                      then $priceBeforeDiscount
                      else $bound + ($priceBeforeDiscount - $bound) * $disc
    )
    return {sup:$s, items:$s.items,
                   priceBeforeDisc: $priceBeforeDisc, price:$priceAfterDisc}
]
let $totalCost := sum (for $s in $perSup[] return $s.price)
let $supAvailability as boolean :=
    every $i in $supInfo[].items[] satisfies $i.qty <= $i.availQty
let $demandSatisfied as boolean :=
    every ( $i in $orderedItems.item
            let $supQty := sum ($it in $supInfo[].items[]
                                    where $it.item = $i
                                    return $it.qty)
    )
    satisfies $i.demQty <= $supQty
let $constraints as boolean := $supAvailability && $demandSatisfied
return {
    demand: [$orderedItems],
    perSup: $perSup,
    orderCost: $totalCost,
    demandSatisfied: $demandSatisfied,
    supplyAvailability: $supAvailability,
    constraints: $constraints
    }
}

// Figure 5    Sample output of compute

collection("sampleOutput.jsn"):
{
  demand:  [
            {item: 1, demQty: 100},
            {item: 2, demQty: 500
            {item: 3, demQty: 130},
            {item: 4, demQty: 50}
           ],
  perSup: [
    {   sup: 15,
        items: [
            { item:1, ppu: 2.0, availQty:   70, qty: 150 },
            { item:2, ppu: 7.5, availQty: 2000, qty: 100 }
        ],
        priceBeforeDisc: 1050.0 ,
        price: 1007.5,
    },
    {   sup: 17,
        items: [
            {item: 1, ppu: 3.8, availQty: 2500, qty: 10 },
            {item: 3, ppu: 3.5, availQty: 5000, qty: 130 },
            {item: 4, ppu: 3.5, availQty: 50,   qty: 200 }
        ],
        priceBeforeDisc: 1193.0,
        price: 1083.7,
    },
    {   sup: 19,
        items: [
            {item: 2, ppu: 6.8, availQty: 1000, qty: 35 }
        ],
        priceBeforeDisc: 238.0,
        price: 232.3,

    }
   ],
orderCost: 2323.5,
demandSatisfied: false,
supplyAvailability: false,
constraints: false
}

// Figure 6, 8, and 11

module namespace my = "http://cs.gmu.edu/~brodsky/sandbox"
import module namespace sp = "www.gmu.edu/~brodsky/jsoniq_dga_example"
// computation:
let $purchase1 := collection("purchase1.jsn")
let $demand1 := collection("demand1.jsn")
return sp:orderAnalytics({purchase: $purchase1, demand: $demand1})


module namespace my = "http://cs.gmu.edu/~brodsky/sandbox"
import module namespace sp = "www.gmu.edu/~brodsky/jsoniq_dga_example"
// optimization:
let $varPurchase1 := collection("varPurchase1.jsn")
let $demand1 := collection("demand1.jsn")
return argmin({ varInput: {purchase : $varPurchase1, demand: $demand1},
            analytics: "sp:orderAnalytics",
            objective: "orderCost"
})



// updated Figure 8 Optimization

module namespace my = "http://cs.gmu.edu/~brodsky/sandbox"
import module namespace sp = "www.gmu.edu/~brodsky/jsoniq_dga_example"
// optimization:
let $varPurchase1 := collection("varPurchase1.jsn")
let $demand1 := collection("demand1.jsn")
let $varInput1 := {purchase : $varPurchase1, demand : $demand1}
let $AM := sp:orderAnalytics#1

return argmin({analytics: $AM, varInput : $varInput1,
               objective: "orderCost"})


// updated Figure 8 Optimization

module namespace my = "http://cs.gmu.edu/~brodsky/sandbox"
import module namespace sp = "www.gmu.edu/~brodsky/jsoniq_dga_example"
// optimization:
let $varPurchase1 := collection("varPurchase1.jsn")
let $demand1 := collection("demand1.jsn")
let $varInput1 := {purchase : $varPurchase1, demand : $demand1}
let $AM := sp:orderAnalytics#1

return minimize($AM, {varInput : $varInput1,
                    objective: "orderCost"}
)



// Figure 11. learning:
// similar to collection("varPurchase1.json") but with volume discounts "float …"
// contains a sequence of {input: …, output: …} pairs;
// input only includes what corresponds to input vars


module namespace my = "http://cs.gmu.edu/~brodsky/sandbox"
import module namespace sp = "www.gmu.edu/~brodsky/jsoniq_dga_example"
// learning
// let $paramPurchaseAndDemand1:={paramPurchase:collection("paramPurchase1.jsn"),
                                             demand:collection("demand1.jsn")}
let $TS:=collection("trainingSet.json")
// let $learningSet1:=collection("learningSet1.jsn")
let $AM := sp:orderAnalytics#1

declare function sp:leastSquares($AM, $inOutPairs) {
// inOutPairs is a JSON array of JSON objects of the form {input: I, output: O}
return(sum(
  for $i in $inOutPairs
  let $sqDiff := ($AM($i.input).cost - $i.output.cost)^2
  return $sqDiff
))
}
$LF := sp:leastSquares#2

return calibrate({model: $AM,
            lossFunction: $LF,
            trainingSet: $TS
})


// Figure 7  varPurchase1.jsn

collection("varPurchase1.jsn"):
// indexable object
{  sup: 15,
    volumeDiscOver: 200,
    volumeDiscRate: 0.05,
    items: [
        { item:1, ppu: 2.0, availQty: 70,   qty: "int ?" },
        { item:2, ppu: 7.5, availQty: 2000, qty: "int ?" }
    ],
 },
 {  sup: 17,
    volumeDiscOver: 100,
    volumeDiscRate: 0.10,
    items: [
        {item: 1, ppu: 3.8, availQty: 2500, qty: "int ?" },
        {item: 3, ppu: 3.5, availQty: 5000, qty: "int ?" },
        {item: 4, ppu: 3.5, availQty: 50,   qty: "int ?" }
    ]
 },
 {  sup: 19,
    volumeDiscOver: 200,
    volumeDiscRate: 0.15,
    items: [
        {item: 2, ppu: 6.8, availQty: 1000, qty: "int ?" }
    ]
 }
// Figure 10  training set
collection("trainingSet"):
{input:
{ demand: [ {item: 1, demQty: 100},
            {item: 2, demQty: 500},
            {item: 3, demQty: 130},
            {item: 4, demQty: 50} ]
purchase: [ {  sup: 15,
               volumeDiscOver: {dgalType: "floatPar"}
               volumeDiscRate: {dgalType: "floatPar"}
               items: [
                  { item:1, ppu: 2.0, availQty: 70,
                    qty: {dgalType: "intVar", values: [10,4,7,1,9]}},
                    values: [10,4,7,1,9]} },
                  { item:2, ppu: 7.5, availQty: 2000,
                    qty: {dgalType: "int ?", values: [10,4,7,1,9]} } ]
              {  sup: 17,
                volumeDiscOver: {dgalType: "floatPar"}
                volumeDiscRate: {dgalType: "floatPar"}
                 items: [
                    {item: 1, ppu: 3.8, availQty: 2500,
                      qty: {dgalType: "intVar", values: [10,4,7,1,9]} },
                    {item: 3, ppu: 3.5, availQty: 5000,
                      qty: {dgalType: "intVar", values: [10,4,7,1,9]} },
                     {item: 4, ppu: 3.5, availQty: 50,
                       qty: {dgalType: "intVar", values: [10,4,7,1,9]} } ]
              },
              {  sup: 19,
                volumeDiscOver: {dgalType: "floatPar"}
                volumeDiscRate: {dgalType: "floatPar"}
                  items: [
                        {item: 2, ppu: 6.8, availQty: 1000,
                          qty: {dgalType: "intVar", values: [10,4,7,1,9]} }
                ]
              }

]}
},
output: {
  orderCost: {dgalType: "floatComp", values: [2500.0, 1000.5, 50.2, 405.0, 3000.0]},
  demandSatisfied: {dgalType: "boolComp", values: [true, true, false, true, true]},
  supplyAvailability: {dgalType: "boolComp", values: [true, true, false, true, true]},
  constraints: {dgalType: "boolComp", values: [true, true, false, true, true]}
}

}

//   Figure 10_old   paramPurchase1.jsn

collection(“paramPurchase1.jsn"):
// indexable object
 {  sup: 15,
    volumeDiscOver: “float ...”,
    volumeDiscRate: “float ...”,
    items: [ { item:1, ppu: 2.0, availQty:   70,  qty: “int ?” },
             { item:2, ppu: 7.5, availQty: 2000,  qty: “int ?” }]
 },
 {  sup: 17,
    volumeDiscOver: “float ...”,
    volumeDiscRate: “float ...”,
    items: [
        {item: 1, ppu: 3.8, availQty: 2500, qty: “int ?”  },
        {item: 3, ppu: 3.5, availQty: 5000, qty: “int ?”  },
        {item: 4, ppu: 3.5, availQty: 50,   qty: “int ?”  }]
 }
 {  sup: 19,
    volumeDiscOver: “float ...”,
    volumeDiscRate: “float ...”,
    items: [
        {item: 2, ppu: 6.8, availQty: 1000, qty: "int ?" }
    ]
 }


 // Figure 13: stochastic

module namespace ns:= www.gmu.edu/~brodsky/jsoniq_dga_example
declare function ns:stochOrderAnalytics($purchase_and_demand) as object {
let
$supInfo := $purchase_and_demand.purchase[]
$suppliers := $supInfo[].sup
$orderedItems := $purchase_and_demand.demand[].item
let $perSup := [
  for $s in $suppliers
  let $priceBeforeDisc := sum (for $si in $supInfo, $i in $s.items[]
                 where $si.sup = $s
                     let $ppu := $si.ppu + Gausian({mean: 0.0, sigma: 0.05 * $si.ppu})
                 return $ppu * $i.qty )
  let $priceAfterDisc :=    if $priceBeforeDisc <= $s.volumeDiscOver
                                      then $priceBeoreDiscount
                                      else $s.volumeDiscOver +
                        ($priceBeforeDiscount - $s.volumeDiscOver) * $s.volumeDiscRate)
  return { sup: $s,  priceBeforeDisc: $priceBeforeDisc,  price: $priceAfterDisc }
]
let $totalCost := sum (for $s in $perSup[] return $s.price)
....
}


// Figure 14  DGAL: simulation, stochastic (1-stage) optimization, learning

module namespace my = "http://cs.gmu.edu/~brodsky/sandbox"
import module namespace sp = www.gmu.edu/~brodsky/jsoniq_dga_example

// simulation:  compute with random choices from distributions
let $purchase1 := collection("purchase1.jsn")
let $order1 :=  collection("demand1.jsn")
return sp:stochOrderAnalytics({purchase: [$purchase1], demand: [$demand1]})

// prediction:
return predict({
                 input: {purchase: $purchase1, demand: $demand1},
                 analytics: "sp:stochOrderAnalytics",
                 sigmaUpperBound: 3.0,
                 confidence: 0.99,
                 timeUpperBound: 120.0
               })

// 1-stage stochastic optimization:
let $varPurchase1 := collection("varPurchase1.jsn")
return minimize({varInput: {purchase : $varPurchase1, demand: $demand1},
             analytics: "sp:stochOrderAnalytics",
             objective: "orderCost”,
             constraintSatProb: 0.95, config: {confidence: 0.99, budget: 10000.0}
             })


// Figure 9   // sample output of optimize

collection("OutputFromOptimization.jsn"):
{ purchase: [
    {   sup: 15,
        volumeDiscOver: 200,
        volumeDiscRate: 0.05,
        items: [
        { item:1, ppu: 2.0, availQty: 70, qty: 70},
        { item:2, ppu: 7.5, availQty: 2000, qty: 0 }
        ]
    },
    {   sup: 17,
        volumeDiscOver: 100,
        volumeDiscRate: 0.10,
        items: [
            {item: 1, ppu: 3.8, availQty: 2500, qty: 30 },
            {item: 3, ppu: 3.5, availQty: 5000, qty: 130 },
            {item: 4, ppu: 3.5, availQty: 50,   qty: 50 }
        ]
    },
    {   sup: 19,
        volumeDiscOver: 200,
        volumeDiscRate: 0.15,
        items: [
            {item: 2, ppu: 6.8, availQty: 1000, qty: 500 }
        ]
    }
 ],
 demand: [
    {item: 1, demQty: 100},
    {item: 2, demQty: 500},
    {item: 3, demQty: 130},
    {item: 4, demQty: 50}
 ]
}


// Figure 12   // sample output of learning

collection(“OutputFromLearning.jsn"):
// indexable object
 {  sup: 15,
    volumeDiscOver: 200,
    volumeDiscRate: 0.05,
    items: [ { item:1, ppu: 2.0, availQty:   70,  qty: “int ?” },
             { item:2, ppu: 7.5, availQty: 2000,  qty: “int ?” }]
 },
 {  sup: 17,
    volumeDiscOver: 100,
    volumeDiscRate: 0.10,
    items: [
        {item: 1, ppu: 3.8, availQty: 2500, qty: “int ?”  },
        {item: 3, ppu: 3.5, availQty: 5000, qty: “int ?”  },
        {item: 4, ppu: 3.5, availQty: 50,   qty: “int ?”  }]
 }
 {  sup: 19,
    volumeDiscOver: 200,
    volumeDiscRate: 0.15,
    items: [
        {item: 2, ppu: 6.8, availQty: 1000, qty: "int ?" }
    ]
 }


//  learningSet example

collection("learningSet1.jsn"):
{ input: { purchase: [
        { sup: 15,
          items: [ {item: 1, qty: 150 }, { item: 2, qty: 100 }],
        },
        { sup: 17,
          items: [ {item: 1, qty: 10 }, {item: 3, qty: 130}, {item: 4, qty: 200}]
        },
        { sup: 19,
          items: [ {item: 2, qty: 35 }]
        }]},
  output: 2329.4
},
{ input: { purchase: [
        { sup: 15,
          items: [ { item: 1, qty: 250 }, { item: 2, qty: 55 }, {item: 3, qty: 50}],
        },
        { sup: 17,
          items: [ {item: 1, qty: 25 }, {item: 4, qty: 130 }]
        },
        { sup: 19,
          items: [ {item: 2, qty: 35 }, {item: 3, qty: 80}]
        }]},
  output: 2390.3
},
     ....    ....
{ input: { purchase: [
        { sup: 15,
          items: [ { item: 1, qty: 90 }, { item: 2, qty: 210 }],
        },
        { sup: 17,
          items: [ {item: 1, qty: 110 }, {item: 3,qty: 28 }, {item: 4, qty: 185 }]
        },
        { sup: 19,
          items: [ {item: 2, qty: 76 }]
        }]},
  output: 3210.6
}

// Figure 15_2    Sample output of stochastic simulation compute

collection("sampleOutput.jsn"):
{
  demand:  [
            {item: 1, demQty: 100},
            {item: 2, demQty: 500},
            {item: 3, demQty: 130},
            {item: 4, demQty: 50}
           ],
  perSup: [
    {   sup: 15,
        items: [
            { item:1, ppu: {expectation: 2.0, stdeviation: 0.05}, availQty:   70, qty: 150 },
            { item:2, ppu: {expectation: 7.5, stdeviation: 0.1}, availQty: 2000, qty: 100 }
        ],
        priceBeforeDisc: 1050.0 ,
        price: 1007.5,
    },
    {   sup: 17,
        items: [
            {item: 1, ppu: {expectation: 3.8, stdeviation: 0.09}, availQty: 2500, qty: 10 },
            {item: 3, ppu: {expectation: 3.5, stdeviation: 0.08}, availQty: 5000, qty: 130 },
            {item: 4, ppu: {expectation: 3.5, stdeviation: 0.08}, availQty: 50,   qty: 200 }
        ],
        priceBeforeDisc: 1193.0,
        price: 1083.7,
    },
    {   sup: 19,
        items: [
            {item: 2, ppu: {expectation: 6.8, stdeviation: 0.1}, availQty: 1000, qty: 35 }
        ],
        priceBeforeDisc: 238.0,
        price: 232.3,

    }
   ],
orderCost: 2350.55,
demandSatisfied: false,
supplyAvailability: false,
constraints: false
}

// Figure 19  A composable supply chain

[
{ id: "mySupplyChain", type: "composite", input: [],
output: ["prod1", "prod2"], inputQty: { },
outputQty: { prod1: 100, prod2: 200 },
subProcesses: [ "combinedSupply", "combinedManuf" ]
},
{ id: "combinedSupply", type: "composite", input: [],
output: ["mat1","mat2"], inputQty: { },
outputQty: { mat1: {dvar: "3", type: "int+"}, mat2: {dvar: "4", type: "int+"} },
subProcesses: [ "supp1", "supp2" ]
},
{ id: "combinedManuf", type: "composite", input: ["mat1","mat2"],
output: ["prod1","prod2"],
inputQty: { mat1: {dvar: "5", type: "int+"}, mat2: {dvar: "6", type: "int+"} },
outputQty: { prod1: {dvar: "7", type: "int+"}, prod2: {dvar: "8", type: "int+"} },
subProcesses: [ "tier1manuf", "tier2manuf" ]
},
{  id: "supp1", type: "supplier", input: [],
output: ["mat1","mat2"], inputQty: { },
outputQty: { mat1 : {dvar: "9", type: "int+"}, mat2: {dvar: "10", type: "int+"} },
ppu: {mat1: 5.0, mat2: 1.0 }
},
{  id: "supp2", type: "supplier", input: [],
output: ["mat1","mat2"], inputQty: { },
outputQty: { "mat1": {dvar: "11", type: "int+"}, "mat2": {dvar: "12", type: "int+"} },
ppu: {mat1: 4.0, mat2: 5.0 }
},
{   id: "tier1manuf", type: "manufacturer",
input: ["mat1","mat2"],
output: ["part1","part2"],
outputQty: { part1: {dvar: "13", type: "int+"}, part2: {dvar: "14", type: "int+"} },
inQtyPer1out: [
{ key : {out: "part1", in: "mat1"}, qty: 2 },
{ key : {out: "part1", in: "mat2"}, qty: 1 },
{ key : {out: "part2", in: "mat2"}, qty: 3 }
],
manufCostPerUnit: { part1: 30.0, part2: 20.0 }
},
{   id: "tier2manuf", type: "manufacturer",
input: ["part1","part2"],
output: ["prod1","prod2"],
outputQty: { prod1: {dvar: "15", type: "int+"}, prod2: {dvar: "16", type: "int+"} },
  inQtyPer1out: [
{ key : {out: "prod1", in: "part1"}, qty: 2 },
{ key : {out: "prod1", in: "part2"}, qty: 1 },
{ key : {out: "prod2", in: "part2"}, qty: 3 }
],
manufCostPerUnit: { prod1: 30.0, prod2: 20.0 }
}
]

// Fig 20

declare function ns:supplierMetrics($suppInput)
{
let $cost := sum (for $i in $suppInput.output[]
                  return ($suppInput.ppu.$i * $suppInput.outputQty.$i)
                 )
return {| ( $suppInput, { cost: $cost, constraints: true } ) |}
};


// Fig 21

declare function ns:manufMetrics($manufInput)
{
let $cost := sum (for $o in $manufInput.output[]
                     return ($manufInput.manufCostPerUnit.$o * $manufInput.outputQty.$o))
let $inputQty := {|
      for $i in $manufInput.input[]
        let $qty := sum (for $ipo in $manufInput.inQtyPer1out[] where $ipo.key.in = $i
                         return ($ipo.qty * $manufInput.outputQty.($ipo.key.out))
                        )
       return { $i:$qty }
                 |}
return {| ( $manufInput, { cost: $cost, constraints: true, inputQty: $inputQty } ) |}
};



// Fig 22
declare function ns:scMetrics($scInput)
{
let $rootProcess := $scInput.kb[][$$.id = $scInput.root]
let $rootType := $rootProcess.type
let $processMetrics := if ($rootType = "supplier") then ns:supplierMetrics($rootProcess)
                       else if ($rootType = "manufacturer") then ns:manufMetrics($rootProcess)
                            else  let $SubProcessMetrics := for $p in $rootProcess.subProcesses[]
                                                 return ns:scMetrics({kb: $scInput.kb, root: $p})
let $FirstLevelSubProcesses := for $p in $rootProcess.subProcesses[]
                               return $SubProcessMetrics[$$.id = $p]

let $cost := sum (for $p in $FirstLevelSubProcesses return $p.cost)
let $subProcessConstraints := every $p in $FirstLevelSubProcesses satisfies $p.constraints = true

let $ProcessItems := distinct-values(($rootProcess.input[], $rootProcess.output[],
(for $p in $FirstLevelSubProcesses
   return ($p.input[], $p.output[]))
))

let $zeroSumConstraints := every $i in $ProcessItems satisfies (
let $itemSupply := $rootProcess.inputQty.$i + sum (for $p in $FirstLevelSubProcesses return $p.outputQty.$i)

let $itemDemand := $rootProcess.outputQty.$i + sum (for $p in $FirstLevelSubProcesses return $p.inputQty.$i)
  return ($itemSupply = $itemDemand)
)
let $constraints := $subProcessConstraints and $zeroSumConstraints

let $rootProcessMetrics := {| $rootProcess, { cost: $cost, constraints: $constraints } |}
    return ($rootProcessMetrics, $SubProcessMetrics)

return $processMetrics
};



// Fig 23

return [ns:scMetrics(dgal:minimize({ varInput: {kb: $exampleVarCompositeInput, root: "mySupplyChain"},
                                   ns: "http://cs.gmu.edu/dgal/supplyChain.jq",
                                   analytics: "scMetrics", objective: "cost"
}))]





  //  ampl example



//Figure 4  -- -updated


module namespace ns:= "www.gmu.edu/~brodsky/jsoniq_dga_example"
declare function ns:orderAnalytics($purchase_and_demand) as object {
let
  $supInfo := $purchase_and_demand.purchase[]
  $suppliers := $supInfo[].sup
  $orderedItems := $purchase_and_demand.demand[]

let $perSup := [
  for $s in $suppliers
    let $priceBeforeDisc := sum ( for $si in $supInfo, $i in $s.items[]
                                    where $si.sup = $s
                                    return $i.ppu * $i.qty
    )
    let $priceAfterDisc := (   let $bound := $s.volumeDiscOver
                 let $disc  := $s.volumeDiscRate
                 return  if $priceBeforeDisc <= $bound
                      then $priceBeforeDiscount
                      else $bound + ($priceBeforeDiscount - $bound) * $disc
    )
   return {sup:$s, priceBeforeDisc: $priceBeforeDisc, price:$priceAfterDisc}
]
let $totalCost := sum (for $s in $perSup[] return $s.price)
let $supAvailability as boolean :=
    every $i in $supInfo[].items[] satisfies $i.qty <= $i.availQty
let $demandSatisfied as boolean :=
    every ( $i in $orderedItems.item
            let $supQty := sum ($it in $supInfo[].items[]
                                    where $it.item = $i
                                    return $it.qty)
    )
    satisfies $i.demQty <= $supQty
let $constraints as boolean := $supAvailability && $demandSatisfied
return {
    orderCost: $totalCost,
    demandSatisfied: $demandSatisfied,
    supplyAvailability: $supAvailability,
    constraints: $constraints,
    perSup: $perSup
   }
}


//Figure 5  -- update  Sample output of compute

collection("sampleOutput.jsn"):
{
  orderCost: 2323.5,
  demandSatisfied: false,
  supplyAvailability: false,
  constraints: false,
  perSup: [
    {   sup: 15,
        priceBeforeDisc: 1050.0 ,
        price: 1007.5,
    },
    {   sup: 17,
        priceBeforeDisc: 1193.0,
        price: 1083.7,
    },
    {   sup: 19,
        priceBeforeDisc: 238.0,
        price: 232.3,
    }
   ]
}

// // updated Figure 8 Optimization for DSS journal 3-31-2021

module namespace my = "http://cs.gmu.edu/~brodsky/sandbox"
import module namespace sp = "www.gmu.edu/~brodsky/jsoniq_dga_example"
// optimization:
let $varPurchase1 := collection("varPurchase1.jsn")
let $demand1 := collection("demand1.jsn")
let $varInput1 := {purchase : $varPurchase1, demand : $demand1}
let $AM := sp:orderAnalytics#1

return minimize({model: $AM, varInput : $varInput1,
               objective: "orderCost"})






// Figure 11. Calibrating:  for DSS journal 3-31-2021
// similar to collection("varPurchase1.json") but with volume discounts "float …"
// contains a sequence of {input: …, output: …} pairs;
// input only includes what corresponds to input vars


module namespace my = "http://cs.gmu.edu/~brodsky/sandbox"
import module namespace sp = "www.gmu.edu/~brodsky/jsoniq_dga_example"
// calibrating
let $paramPurchaseAndDemand1:={paramPurchase:collection("paramPurchase1.jsn"),
                                             demand:collection("demand1.jsn")}
let $learningSet1:=collection("learningSet1.jsn")
let $AM := sp:orderAnalytics#1
return calibrate({model: $AM,
            paramInput: $paramPurchaseAndDemand1,
            outValue: "orderCost",
            learningSet: [$learningSet1]
})



// Figure 14. update  for DSS journal 3-31-2021

module namespace my = "http://cs.gmu.edu/~brodsky/sandbox"
import module namespace sp = www.gmu.edu/~brodsky/jsoniq_dga_example

// simulation:  compute with random choices from distributions
let $purchase1 := collection("purchase1.jsn")
let $order1 :=  collection("demand1.jsn")
return sp:stochOrderAnalytics({purchase: [$purchase1], demand: [$demand1]})

// prediction:
let $AM := stochOrderAnalytics#1
return predict({
				 model: $AM,
                 input: {purchase: $purchase1, demand: $demand1},
                 sigmaUpperBound: 3.0,
                 confidence: 0.99,
                 timeUpperBound: 120.0
               })

// 1-stage stochastic optimization:
let $varPurchase1 := collection("varPurchase1.jsn")
return minimize(
            {
			 model: $AM,
		     varInput: {purchase : $varPurchase1, demand: $demand1},
             objective: "orderCost”,
             constraintSatProb: 0.95, config: {confidence: 0.99, budget: 10000.0}
            })
