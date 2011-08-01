
__constant sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST;



__kernel void GVFInit(__read_only image3d_t volume, __write_only image3d_t vector_field ) {
    // Calculate gradient using a 1D central difference for each dimension, with spacing 1
    int4 pos = {get_global_id(0), get_global_id(1), get_global_id(2), 0};

    half f = read_imageh(volume, sampler, pos).x;
    half fx1 = read_imageh(volume, sampler, pos + (int4)(1,0,0,0)).x;
    half fx_1 = read_imageh(volume, sampler, pos - (int4)(1,0,0,0)).x;
    half fy1 = read_imageh(volume, sampler, pos + (int4)(0,1,0,0)).x;
    half fy_1 = read_imageh(volume, sampler, pos - (int4)(0,1,0,0)).x;
    half fz1 = read_imageh(volume, sampler, pos + (int4)(0,0,1,0)).x;
    half fz_1 = read_imageh(volume, sampler, pos - (int4)(0,0,1,0)).x;

    half4 gradient = {
        fx1 - 2*f + fx_1,
        fy1 - 2*f + fy_1,
        fz1 - 2*f + fz_1,
        0};

    gradient.w = gradient.x*gradient.x + gradient.y*gradient.y + gradient.z*gradient.z;

    write_imageh(vector_field, pos, gradient); 

}

__kernel void GVFIteration(__read_only image3d_t init_vector_field, __read_only image3d_t read_vector_field, __write_only image3d_t write_vector_field, __private float mu) {
    // TODO: Enforce mirror boundary conditions

    // Update the vector field. Calculate Laplacian using a 3D central difference scheme
    int4 pos = {get_global_id(0), get_global_id(1), get_global_id(2), 0};

    half4 vector = read_imageh(read_vector_field, sampler, pos);
    half4 fx1 = read_imageh(read_vector_field, sampler, pos + (int4)(1,0,0,0));
    half4 fx_1 = read_imageh(read_vector_field, sampler, pos - (int4)(1,0,0,0));
    half4 fy1 = read_imageh(read_vector_field, sampler, pos + (int4)(0,1,0,0));
    half4 fy_1 = read_imageh(read_vector_field, sampler, pos - (int4)(0,1,0,0));
    half4 fz1 = read_imageh(read_vector_field, sampler, pos + (int4)(0,0,1,0));
    half4 fz_1 = read_imageh(read_vector_field, sampler, pos - (int4)(0,0,1,0));
    half4 init_vector = read_imageh(init_vector_field, sampler, pos);

    half4 laplacian = -6*vector + fx1 + fx_1 + fy1 + fy_1 + fz1 + fz_1;

    vector += mu * laplacian + (vector - init_vector)*init_vector.w;

    write_imageh(write_vector_field, pos, vector);
}
