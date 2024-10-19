use alloy_primitives::utils::keccak256 as keccak;

#[no_mangle]
pub extern "C" fn keccak256(data_ptr: *const u8, data_len: usize, result_ptr: *mut u8) {
    let data = unsafe { std::slice::from_raw_parts(data_ptr, data_len) };
    let hash = keccak(&data);
    let hash = hash.as_slice();
    let result = unsafe { std::slice::from_raw_parts_mut(result_ptr, 32) };
    result.copy_from_slice(hash);
}
