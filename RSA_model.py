

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

def parallel_binary_method(M, e, n, VERBOSE =False):
    k = max(M.bit_length(),e.bit_length())

    C_1 = 0
    P_1 = 0
    C_0 = 1
    P_0 = M
    for i in range (0,  k):
        if(VERBOSE):
            print("C0:", hex(C_0), "C1:", hex(C_1), "P0:", hex(P_0), "P1:", hex(P_1), bit_at(e, i))
        P_1_prev = P_1
        C_1_prev = C_1
        P_1 = blakleys_method(P_0,P_0,n)
        
        if(bit_at(e, i) == 1):
            C_1 = blakleys_method(P_0, C_0, n)
        else:
            C_1 = C_0
        #print("P0_nxt:", hex(P_1_prev), "P1_nxt:", hex(P_1))
        C_0 = C_1
        P_0 = P_1
        

    return C_1
    

def blakleys_method(A ,B, n, VERBOSE =False):
    k = max(A.bit_length(),B.bit_length())
    if(VERBOSE):
        print("Bitlength: ",k)
        k = 16
    P = 0
    
    for i in range(k, -1, -1):
        tP = 2*P
        A_and_b = A * bit_at(B, i)
        P = tP + A_and_b
        sum0 = P
        #P = P % n
        if(P - 2*n >= 0):
            P = P - 2*n
        elif(P >= n):
            P = P - n
            #print(P)
        if(VERBOSE):
            print(hex(P), bit_at(B, i))
            print("sum0:", hex(sum0), "Pnxt:",hex(P), "Pshift: ", hex(tP))
            print("sum2:", hex((sum0 - 2*n) & 0x3ffff), "sum1:",hex((sum0 -n) & 0x3ffff))
        #print("sum0:", sum0, "Pnxt:",P)
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
    A = 0x2bbfa64d5ad35948fa2a10eb53b78099adbecfd2557a1ae21e5b8840836c1ac8 # 46
    B = 0x0a232020207478742e6e695f307470203a2020202020202020202020454d414e #2
    n = 0x099925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d #56
    minus = 0x3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    golden =( A * B) % n
    test = blakleys_method(A, B, n)
    print("m2N:", hex(-2*n & minus))
    print("mN:", hex(-n & minus))
    print("G_blakley:", hex(golden), "test_blakley: ", hex(test)) 
    #exit()
    ## Test Binary + Blakley

    # print("### Binary method test")

    M = 0x0A23232323232323232323232323232323232323232323232323232323232323
    e = 0x0000000000000000000000000000000000000000000000000000000000010001
    n = 0x99925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d
    d = 0x0cea1651ef44be1f1f1476b7539bed10d73e3aac782bd9999a1e5a790932bfe9
    
    # crypt = (binary_method(M, e, n))
    
    # gold_crypt = (M**e) % n
    
    # print("Crypted: ", (crypt))
    # print("Correct crypted: ", (gold_crypt))
    
    # decrypt = (binary_method(crypt, d, n))
    
    # gold_decrypt = (gold_crypt**d) % n
    
    # print("Decrypted: ", decrypt)
    # print("Correct decrypted: ", (gold_decrypt))
    
    # print("Actual: ", M)
    

    print("### Paralell binary method test")
    
    crypt = (parallel_binary_method(M, e, n,VERBOSE=False))
    
    gold_crypt = (M**e) % n
    
    print("Crypted: ", hex(crypt))
    print("Correct crypted: ", hex(gold_crypt))
    # print(hex((-n) & 0x3ffff))
    # print(hex((-2*n) & 0x3ffff))
    # print(hex(blakleys_method(0x7a77,0x7a77,n, VERBOSE=True)))
    # print(hex(0x7a77*0x7a77 % n))
    
    # print(hex( (0x01409 - n ) & 0x3ffff))
    # print(hex(0x93b3*2))
    #decrypt = (parallel_binary_method(crypt, d, n))
    
    # gold_decrypt = (gold_crypt**d) % n
    
    # print("Decrypted: ", hex(decrypt))
    # print("Correct decrypted: ", hex(gold_decrypt))
    
    # print("Actual: ", M)
    
    



# %%
