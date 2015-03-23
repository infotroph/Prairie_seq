
order.plate = function(wellvector){
# Takes a vector of strings that look like well IDs for a 96-well plate,
# returns a vector of indexes to sort them in plate order.
#
# "Looks like well IDS" = one letter followed by a 1- or 2-digit number.
# "Plate order" = "A10" comes after "A2", not before.
# 
# Example: if ex = c("A1", "A10", "A11", "A12", "A2", "A3"), then
# order.plate(ex) ==> c(1,5,6,2,3,4) 
# ex[order.plate(ex)] ==> c("A1", "A2", "A3", "A10", "A11", "A12")
order(
	substr(wellvector, 1, 1), 
	as.numeric(substr(wellvector, 2, 3)))
}