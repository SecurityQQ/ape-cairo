// NOTE: This contract is for test purposes only.
// Its intent is to provide a variety of ABI types to test against.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import library_call_l1_handler, library_call

// Make sure we can import libraries
from openzeppelin.upgrades.library import Proxy

// Make sure we can compile structs.
struct Point{
    x: felt,
    y: felt,
}

// Make sure we can compile storage variables
@storage_var
func balance() -> (res : felt){
}

// Make sure constructors work
@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(implementation_address: felt) {
    Proxy._set_implementation_hash(implementation_address);
    return ();
}

// Make sure we can compile method with pointer arguments.
@external
func compare_arrays(
    a_len : felt, a : felt*, b_len : felt, b : felt*
) {
    assert a_len = b_len;
    if (a_len == 0) {
        return ();
    }
    assert a[0] = b[0];
    return compare_arrays(
        a_len=a_len - 1, a=&a[1], b_len=b_len - 1, b=&b[1]
    );
}

// An invoke-function transaction we can easily call in tests.
@external
func increase_balance{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(amount : felt) {
    let (res) = balance.read();
    balance.write(res + amount);
    return ();
}

// A READ we can easily call in tests.
@view
func get_balance{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (res : felt) {
    let (res) = balance.read();
    return (res=res);
}

// Make sure can compile method that uses structs.
@view
func sum_points(points : (Point, Point)) -> (res : Point) {
    return (
        res=Point(
        x=points[0].x + points[1].x,
        y=points[0].y + points[1].y),
    );
}

// Make sure fallback options work.
@external
@raw_input
@raw_output
func __default__{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        selector: felt,
        calldata_size: felt,
        calldata: felt*
    ) -> (
        retdata_size: felt,
        retdata: felt*
    ) {
    let (class_hash) = Proxy.get_implementation_hash();

    let (retdata_size: felt, retdata: felt*) = library_call(
        class_hash=class_hash,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata,
    );

    return (retdata_size=retdata_size, retdata=retdata);
}

@l1_handler
@raw_input
func __l1_default__{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        selector: felt,
        calldata_size: felt,
        calldata: felt*
    ) {
    let (class_hash) = Proxy.get_implementation_hash();

    library_call_l1_handler(
        class_hash=class_hash,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata,
    );

    return ();
}
