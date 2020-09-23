

# %%
def binary_method(M, e, n):
    k = e.bit_length()
    C = 1
    if(bit_at(e, k - 1) == 1):
        C = M
    for i in range (k - 2, -1, -1):
        C = blakleys_method(C,C,n)
        if(bit_at(e, i) == 1):
            C = blakleys_method(C, M, n)
    return C

def parallel_binary_method(M, e, n):
    k = e.bit_length()
    Rs_1 = 0
    Ps_1 = 0
    Rs_0 = 1
    Ps_0 = M
    
    for i in range (0,  k):
        Ps_1 = blakleys_method(Ps_0,Ps_0,n)
        if(bit_at(e, i) == 1):
            Rs_1 = blakleys_method(Ps_0, Rs_0, n)
        else:
            Rs_1 = Rs_0
        Rs_0 = Rs_1
        Ps_0 = Ps_1

    return Rs_1
    

def blakleys_method(A ,B, n):
    k = B.bit_length()
    P = 0
    for i in range(k, -1, -1):
        P = 2*P + A * bit_at(B, i)
        #P = P % n
        if( P >= n):
            P = P - n
        if( P >= n):
            P = P - n
            
        if( P >= n):
            assert "mod n overflow!"
    return P

def set_bit_at(value, index, bit):
    return value ^ (-bit ^ value) & (1 << index)

def bit_at(value, index):
    bit = (value & (1 << index))
    if(bit >= 1):
        return 1
    else:
        return 0

if __name__ == "__main__":
    

    print("### Blakley method test")
    ## Test Blakley
    A = 0b11100101
    B = 0b11011
    n = 0b11011001000
    golden =( A * B) % n
    test = blakleys_method(A, B, n)
    print("G_blakley:", golden, "test_blakley: ", test) 
    
    ## Test Binary + Blakley

    print("### Binary method test")

    M = 0b101110
    e = 0b101
    n = 0b1110111
    d = 0b1001101
    
    crypt = (binary_method(M, e, n))
    
    gold_crypt = (M**e) % n
    
    print("Crypted: ", (crypt))
    print("Correct crypted: ", (gold_crypt))
    
    decrypt = (binary_method(crypt, d, n))
    
    gold_decrypt = (gold_crypt**d) % n
    
    print("Decrypted: ", decrypt)
    print("Correct decrypted: ", (gold_decrypt))
    
    print("Actual: ", M)
    

    print("### Paralell binary method test")
    
    crypt = (parallel_binary_method(M, e, n))
    
    gold_crypt = (M**e) % n
    
    print("Crypted: ", (crypt))
    print("Correct crypted: ", (gold_crypt))
    
    decrypt = (parallel_binary_method(crypt, d, n))
    
    gold_decrypt = (gold_crypt**d) % n
    
    print("Decrypted: ", decrypt)
    print("Correct decrypted: ", (gold_decrypt))
    
    print("Actual: ", M)
    
    


