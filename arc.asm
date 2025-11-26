
#leen alqazaqi 1220380
# duha imad 1220623

#registers $s2,$s3 are used to store the address for three arrays so they cannot be used for anything else
    # $s2 has the address for the items array 
    #$s3 is the address for the bins array 
    # $s0 has the file descriptor
    #s1 for the number of bins 
    
    .data
    # filename:   .asciiz "C:\\Users\\User\\Desktop\\university\\second semester year 3\\arc\\input.txt"
     file_msg: .asciiz "Enter the input file path: "  # Prompt for input file name
      fileName: .space 100
     output_file: .asciiz "C:\\Users\\User\\Desktop\\university\\second semester year 3\\arc\\output.txt"
     errorMsg: .asciiz "error opening the file\n"
     emptyMsg: .asciiz "file is empty!\n"
     stringMsg: .asciiz "enter valid string please\n"
     buffer:     .space 4000  
     temp_str:    .space 20 
     temp_bin: .space 4   
     temp_item: .space 4
     temp_min_bins: .space 4
     new_line:    .asciiz "\n"
     zero: .float 0.0 
     one:  .float 1.0
     menu_options: .asciiz "please enter FF for First Fit, BF for Best Fit,or Q,q to quit\n"
     choice_buffer: .space 100
     best_fit: .asciiz "bf"
     first_fit: .asciiz "ff"
     quit: .asciiz "q"
     out1: .asciiz "I"
     out2: .asciiz " was added to bin "
     output_buffer: .space 22

    bins_out_string: .asciiz "minimum bins:" #is used to add the minimum number of bins used
    the_string: .asciiz "minimum bins:"
     bins_output_buffer: .space 15
     bins_num:    .space 10
     index_bin:   .space 10             # Space for first number string
     index_item:   .space 10            # Space for second number string
     min_bin:   .space 10 
    .text
main:
     move $fp, $sp #save the base pointer
    #To print "enter the input file"
     li $v0, 4
     la $a0, file_msg   
     syscall
     
     # Read file path from user input
     li $v0, 8    # syscall to read string
     la $a0, fileName     
     li $a1, 100
     syscall
     
     la $t0, fileName

newline_check:
    lb $t1, 0($t0)        
    beqz $t1, file_done 
    beq $t1, 0x0A, remove_newline1 
    addi $t0, $t0, 1
    j newline_check

remove_newline1:
    sb $zero, 0($t0)     
    
file_done:

  
    # open the file to read items from
    li $v0, 13
    la $a0, fileName
    li $a1, 0 #read only
    li $a2, 0
    syscall
    move $s0,$v0
    #checks for errors, if there is no errors it jumps to label next
    bgez $s0,read_from_file
    #prints an error message if there is an error opening the file 
    la $a0,errorMsg
    li $v0,4
    syscall

    # Exit program after error
    li $v0, 10   # Syscall code for exit
    syscall

read_from_file:

     li $t0, 0
     li $t1, 4000
     la $t2, buffer

clear_buffer:
    beq $t0, $t1, done_clear_buffer
    sb $zero, 0($t2)
    addi $t2, $t2, 1
    addi $t0, $t0, 1
    j clear_buffer
done_clear_buffer:


 #read from the file we opened to the buffer
     li $v0, 14 
     move $a0, $s0
     la $a1, buffer
     li $a2, 4000
     syscall
     move $s1,$v0 #num of bytes read
     

    #if the file is empty do something
    bgtz $s1, calculate_Number_Of_Items

    #if the file is empty print a message and exit
    la $a0,emptyMsg
    li $v0,4
    syscall
    # Exit program after empty error
    li $v0, 10   # Syscall code for exit
    syscall

#if the file is not empty we will start to filling the items array with the data in the buffer (we do that so we can get the sum of all items)
#the sum is used to know what is the number of the bins 
calculate_Number_Of_Items:
     #create the items array dynamically 
     #calculate items num
     li $t0, 3 
     divu $s1, $t0 
     mflo $s1 

     li $t0, 2 
     divu $s1, $t0
     mflo $t7

     li $t0, 1
     sub $t7,$t7,$t0
     sub $s1,$s1,$t7 #number of items inside s1

     li $t1, 4 #size of each element 
     mul $t2, $s1, $t1 #total size of the array = size of each item * num of elements
     sub $sp, $sp, $t2 #move sp -stack pointer- to allocate memory for the array
     move $s2, $sp # $s2 stores the address for the items array 

    #NOW we need to parse data inside the buffer and fill the array    
parse_items:
      la $t0, buffer
      move $t1,$s2  ##################################################################
      li $t2, 0 #for the integer part
      la   $a0, zero   # Load the address of zero into $a0
      l.s  $f3, 0($a0) 
      li $t4, 1 #for the dividors, 1,10,100,...
      li $t5, 0 #flag to tell us if this part is an integer or a float 0 = integer 1= fraction

parse_loop:
     lb $t6, 0($t0) #loads a character from the buffer to $t6
     #if zero then the data ended and the parse stops
     beqz $t6, parse_done
     #check if the character is a space
     beq $t6, ' ',store_float

     #check if it is a dot
     beq $t6, '.',switch_to_fraction
     #if we did not jump yet then the charatcter is a number!
     #convert from string to digit
     sub $t6, $t6, '0'
     #if it was the integer part
     beqz $t5, parse_integer_part
     j parse_float_part

parse_integer_part:
      mul $t2, $t2, 10
      add $t2, $t2, $t6 #add the digit
      j next_character 

switch_to_fraction:
      li $t5, 1
      j next_character

parse_float_part:
    mul $t4, $t4, 10 #increase the divisor
    mtc1  $t6, $f2      # Move numerator (integer) to floating-point register
    mtc1  $t4, $f4      # Move denominator (integer) to floating-point register
    cvt.s.w $f2, $f2    # Convert integer to float
    cvt.s.w $f4, $f4    # Convert integer to float
    div.s  $f0, $f2, $f4 # Perform floating-point division (f0 = f2 / f4)
    add.s $f3, $f3, $f0 #add it to the fraction part
    j next_character

 
store_float:
     mtc1 $t2, $f0 #move the integer part
     cvt.s.w $f0,$f0 #convert to float after mtc1 is used

     
     add.s $f0,$f0,$f3 #sum od the int & fraction
     #store inside our array
     s.s $f0, 0($t1)   # Store float in array at address $t1
     addi $t1, $t1, 4  # Move to the next element
     

     #reset all values for the next number
      li $t2, 0 #for the integer part
      la   $a0, zero   # Load the address of zero into $a0
      l.s  $f3, 0($a0)
      li $t4, 1 #for the dividors, 1,10,100,...
      li $t5, 0 #flag to tell us if this part is an integer or a float 0 = integer 1= fraction 
next_character:
     addi $t0, $t0, 1 #move the buffer pointer    
     j parse_loop

parse_done:
        #storing the last element in the buffer 
     mtc1 $t2, $f0 #move the integer part
     cvt.s.w $f0,$f0 #convert to float after mtc1 is used
    
     add.s $f0,$f0,$f3 #sum od the int & fraction
     #store inside our array
     s.s $f0, 0($t1)   # Store float in array at address $t1
     addi $t1, $t1, 4  # Move to the next element
         # Close file //done with the file    
      li $v0, 16        
      move $a0, $s0    
      syscall   



     #calculate the number of bins
calculate_bins_num:
         l.s $f2, zero
         move $t1, $s2
calculation_loop:
        #caculate the summation of all items
         lw $t3, 0($t1)
         beqz $t3, end_calculation
         l.s $f1,0($t1)
         add.s $f2,$f2,$f1
         addi $t1, $t1, 4
         j calculation_loop

end_calculation:
        #use the sum we found to calculate the bins number 
        #there is no ceil in assembly so we move it from float register to normal one to remove the fraction
        #after removing the float we add 2 (1 for the fraction we removed and the other 1 we assumed if the sorting was not the best)
        cvt.w.s $f2, $f2
        mfc1 $t2, $f2
        addi $t2, $t2, 2
        move $t2, $s1
        

        #bins minimal number is now in the register $t2 we will use to create a dynamic array
        #bins array 
create_bins_array:
       li $t1, 4 #size of each element in the array 
       mul $t2, $t2, $t1 #the total size of the array is the size of each element * number of bins
       sub $sp, $sp, $t2 #move the stack pointer to allocate space for the dynamcially allocated array
       move $s3,$sp #stores a pointer pointing to the bins arrat (the array is for tracking the sizes of the bins)
       #now we need to fill all bins with 1.0 as begining (it will start getting smaller and smaller as more items are added)
       la $a0, one   # Load the address of one into $a0
       l.s $f3, 0($a0)
       move $t3, $s3
       li $t4, 0 #set a counter for the bins
       
initialize_bins:
       bge $t4, $t2, end_initialization  # Exit loop when t4 >= t2
       s.s $f3, 0($t3)  # Store 1.0 at the current bin position
       addi $t3, $t3, 4
       addi $t4, $t4, 4 #increment the pointer when it equals the num of bins exit the loop
       j initialize_bins 

end_initialization:
#this is for debugging only
      # Assuming $s3 points to the base address of the array
         #   li $t4, 4          # Offset to the 5th element (0-based index, 5th element is at index 4)
       #   mul $t4, $t4, 4    # Multiply by 4 to get byte offset (4 * 4 = 16)
       #  add $t3, $s3, $t4  # Calculate the address of the 5th element
        # l.s $f4, 0($t3)    # Load the value of the 5th element into $f4     

       #########################################################################
       #now its time for FF or BF !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
       #first open output file so we fill it with what elements were entered (no need for one more array) DONE
       #track the items as sizes only to fill each bin with its size at the end in the output file then close it 
       #output file ....... itemX was entered to binY ................................ each bin size was 1 and at the end
       #binX size : R ....... binY size : A .......................................................

menu_loop:
     #we open the file inside the loop so we make sure that if the user chooses another approach later, it will overwrite over the previously chosen one
     #to not get an error since it is already opened we close it before opening it again
      bgez $s0, close_file 

open_file:
      la $a0, output_file
      li $v0, 13
      li $a1, 1 #write only
      li $a2, 0
      syscall
      move $s0,$v0
      #checks for errors, if there is no errors it jumps to label next
      bgez $s0,skip
      #prints an error message if there is an error opening the file 
      la $a0,errorMsg
      li $v0,4
        syscall
        j menu_loop
close_file:
     li $v0, 16    # Close file syscall
    move $a0, $s0 # Pass file descriptor
    syscall
    #if we do not change it we might think the file is still open which causes an error 
    li $s0, -1    # Reset $s0 to indicate file is closed 
    j open_file   # Reopen the file


skip:
     la $a0, menu_options
     li $v0, 4
     syscall

     li $v0, 8
     la $a0, choice_buffer
     li $a1, 100
     syscall

         # Remove newline 
     li $t0, '\n'
     la $t1, choice_buffer  # Load input address

remove_newline:
    lb $t2, 0($t1)       # Load byte from input
    beqz $t2, check  # If null terminator, go to comparison
    beq $t2, $t0, replace_newline  # If newline, replace with null terminator
    addi $t1, $t1, 1      # Move to next character
    j remove_newline      # Loop

replace_newline:
    sb $zero, 0($t1)     # Replace newline with null terminator

check:
     #compare input with FF
     la $a1, first_fit    # first_fit
     jal strcmp
     beqz $v0, FF           # If strcmp returns 0, go to FF

     #compare input with BF
     la $a1, best_fit    # best_fit
     jal strcmp
     beqz $v0, BF          # If strcmp returns 0, go to FF

     #compare input with Q
     la $a1, quit     # quit
     jal strcmp
     beqz $v0, quit_menu         # If strcmp returns 0, go to FF
     
     la $a0, stringMsg
     li $v0, 4
     syscall
     j menu_loop
     
#all good tell here 
FF:
   move $t4, $s2 # pointer for items array
   move $t3, $s3 # pointer for bins array
   li $t0, 0
   mtc1 $t0, $f1       # Move integer zero to float register once outside loo
   cvt.s.w $f1, $f1    # Convert to float (important!)
    andi $t4, $t4, 0xFFFFFFFC  # Ensure word alignment
     andi $t3, $t3, 0xFFFFFFFC
    li $s4, 0 # to keep the number of the bins used 
  FF_loop:
      #code for FF
      #if items are done (the value in the (pointer) is zero then jump to finish)
     # Load item value
     l.s $f4, 0($t4)
      c.eq.s $f4, $f1
      bc1t finish_FF   # If item is zero, finish
      #load the values in bins and items
      l.s $f2, 0($t4)
      l.s $f3, 0($t3)
      c.lt.s $f3, $f2
       bc1t not_enough  # If bin is too small, check next bin

      j enough

 not_enough:
     addi $t3, $t3, 4
     sub $t7, $t3, $s3
     bgt $s4, $t7, its_greater
     #saves the highest index of bins so we can print how many bins is used
     move $s4, $t7
its_greater:
     j FF_loop

  enough:
    sub.s $f3, $f3, $f2
    s.s $f3, 0($t3) 
    #write on the file somehow ##################################################

    li  $t5, 4
    sub $t7, $t3, $s3 #the bin index 
    div $t7, $t5
    mflo $t7
    addi $t7,$t7, 1 # the bin final number starting from 1

    #convert numbers to strings so we can write it on the file 

    la $a0, index_bin
    move $a1, $t7
    jal int_to_string

    la $t0, index_bin
    lb $t1, 8($t0)
    sb $t1, temp_bin
    li $v0, 4
    la $a0, temp_bin
    syscall # debug

    sub $t6, $t4, $s2 #the item index 
    li  $t5, 4
    div $t6, $t5
    mflo $t6
    addi $t6,$t6, 1 # the item final number starting from 1
    
    la $a0, index_item
    move $a1, $t6
    jal int_to_string # the error is in this function!!!!

    la $t0, index_item
    lb $t1, 8($t0)
    sb $t1, temp_item

    li $v0, 4
    la $a0, temp_item
    syscall # debug

    #debug
    #la $t0, index_bin
    #lb $t1, 0($t0)

    # build the message in the buffer to write it on the file
    la $a0, output_buffer
    la $a1, out1
    jal strcat 

    la $a1, temp_item
    jal strcat

    la $a1, out2
    jal strcat

    la $a1, temp_bin
    jal strcat

    la $a1, new_line
    jal strcat

    li $v0, 4
    la $a0, output_buffer
    syscall
    #write to the file 
    li $v0, 15
    move $a0, $s0
    la $a1, output_buffer
    li $a2, 22
    syscall
    # Clear the output_buffer after writing
    la $t0, output_buffer     # Starting address of buffer
    li $t1, 22                # Number of bytes to clear

  

clear_loop:
    beqz $t1, clear_done      # Exit when done
    sb $zero, 0($t0)          # Store zero byte
    addi $t0, $t0, 1          # Move to next byte
    subi $t1, $t1, 1          # Decrease counter
    j clear_loop

clear_done:


    addi $t4, $t4, 4 #move to the next item
    move $t3, $s3 #reset the bins pointer to start all over again 
    j FF_loop


finish_FF: 

          #to write the minimal number of bins to the file 
          #the number of bins used is actually written to $s4 and it is the minimum number we would need
              li  $t5, 4
              div $s4,$s4,$t5
              mflo $s4
              addi $s4,$s4,1

              la $a0, min_bin
              move $a1, $s4
              jal int_to_string

              la $t0, min_bin
              lb $t1, 8($t0)
              sb $t1, temp_min_bins

             


            # write the result to the bin
                      # put the string in the buffer 
              la $a0, bins_output_buffer
               la $a1, the_string
               jal strcat

              la $a1, temp_min_bins
              jal strcat
                
                  la $a1, new_line
                  jal strcat


                li $v0, 15
                move $a0, $s0
               la $a1, bins_output_buffer
                li $a2, 15
               syscall


      li $v0, 16
      move $a0, $s0
      syscall
     
           # Close file //done with the file    
     li $v0, 16        
     move $a0, $s0    
     syscall   
      move $sp, $fp 
      j main



BF:
  #code for BF
   move $t4, $s2 # pointer for items array
   move $t3, $s3 # pointer for bins array the current bin
   move $t6, $s3 # pointer for bins array to iterate over all bins
   li $t0, 0
   mtc1 $t0, $f1       # Move integer zero to float register once outside loo
   cvt.s.w $f1, $f1    # Convert to float (important!)
    andi $t4, $t4, 0xFFFFFFFC  # Ensure word alignment
     andi $t3, $t3, 0xFFFFFFFC
     andi $t6, $t6, 0xFFFFFFFC
    li $s4, 0 # to keep the number of the bins used 

   BF_loop:
   #the pointer for the items array 
      l.s $f4, 0($t4)
      c.eq.s $f4, $f1
      bc1t finish_BF   # If item is zero, finish
      #load the values in bins and items
      l.s $f2, 0($t4)
      l.s $f3, 0($t3)
      c.lt.s $f3, $f2
       bc1t not_enough2  # If bin is too small move the bin it is not good
       
      j enough2

 not_enough2:
     addi $t3, $t3, 4
     sub $t7, $t3, $s3
     bgt $s4, $t7, its_greater2
     move $s4, $t7
its_greater2:
     j BF_loop

enough2:
      move $t6, $s3
      andi $t6, $t6, 0xFFFFFFFC
      l.s $f8, 0($t6)
      li $t7, -1
      #the problem is in this loop
  inner_loop:

     l.s $f8, 0($t6) #reload the bin to the register

     addi $t7, $t7, 1
     beq $t7, $s1, end_inner_loop
     #check if the value of the bin is less than ou bin
     c.le.s $f3, $f8
     #if no jump
     bc1t skip_bin
     #check if the item can fit in the new bin (smaller than ours) 
     c.le.s $f8, $f2
     #if no reloop
     bc1t skip_bin

     #if it smaller andd the item can fit in it then replace our bin by the new min bin (new best fit)
     move $t3, $t6
 skip_bin:
     addi $t6, $t6, 4
     j inner_loop

end_inner_loop:


  ###########################################################################################
   sub.s $f3, $f3, $f2
    s.s $f3, 0($t3) 
    #write on the file somehow ##################################################

    li  $t5, 4
    sub $t7, $t3, $s3 #the bin index 
    div $t7, $t5
    mflo $t7
    addi $t7,$t7, 1 # the bin final number starting from 1

    #convert numbers to strings so we can write it on the file 

    la $a0, index_bin
    move $a1, $t7
    jal int_to_string

    la $t0, index_bin
    lb $t1, 8($t0)
    sb $t1, temp_bin
    li $v0, 4
    la $a0, temp_bin
    syscall # debug

    sub $t6, $t4, $s2 #the item index 
    li  $t5, 4
    div $t6, $t5
    mflo $t6
    addi $t6,$t6, 1 # the item final number starting from 1
    
    la $a0, index_item
    move $a1, $t6
    jal int_to_string # the error is in this function!!!!

    la $t0, index_item
    lb $t1, 8($t0)
    sb $t1, temp_item

    li $v0, 4
    la $a0, temp_item
    syscall # debug

    #debug
    #la $t0, index_bin
    #lb $t1, 0($t0)

    # build the message in the buffer to write it on the file
    la $a0, output_buffer
    la $a1, out1
    jal strcat 

    la $a1, temp_item
    jal strcat

    la $a1, out2
    jal strcat

    la $a1, temp_bin
    jal strcat

    la $a1, new_line
    jal strcat

    li $v0, 4
    la $a0, output_buffer
    syscall
    #write to the file 
    li $v0, 15
    move $a0, $s0
    la $a1, output_buffer
    li $a2, 22
    syscall
    # Clear the output_buffer after writing
    la $t0, output_buffer     # Starting address of buffer
    li $t1, 22                # Number of bytes to clear

  

clear_loop2:
    beqz $t1, clear_done2      # Exit when done
    sb $zero, 0($t0)          # Store zero byte
    addi $t0, $t0, 1          # Move to next byte
    subi $t1, $t1, 1          # Decrease counter
    j clear_loop2

clear_done2:


    addi $t4, $t4, 4 #move to the next item
    move $t3, $s3 #reset the bins pointer to start all over again 
    j BF_loop



finish_BF:
             #to write the minimal number of bins to the file 
          #the number of bins used is actually written to $s4 and it is the minimum number we would need
              li  $t5, 4
              div $s4,$s4,$t5
              mflo $s4
              addi $s4,$s4,1

              la $a0, min_bin
              move $a1, $s4
              jal int_to_string

              la $t0, min_bin
              lb $t1, 8($t0)
              sb $t1, temp_min_bins

             


            # write the result to the bin
                      # put the string in the buffer 
              la $a0, bins_output_buffer
               la $a1, the_string
               jal strcat

              la $a1, temp_min_bins
              jal strcat
                
                  la $a1, new_line
                  jal strcat


                li $v0, 15
                move $a0, $s0
               la $a1, bins_output_buffer
                li $a2, 15
               syscall


      li $v0, 16
      move $a0, $s0
      syscall
     
           # Close file //done with the file    
     li $v0, 16        
     move $a0, $s0    
     syscall   
     move $sp, $fp 
     j main





quit_menu:
     
     # Close file //done with the file    
     li $v0, 16        
     move $a0, $s0    
     syscall   

     li $v0, 10   # Syscall code for exit
     syscall




# strcmp function that compares two null terminated strings
# $a0 = user input, $a1= stored command
#returns value in $v0 , 0 if equal and 1 if not 
#case insensitive 
strcmp:

    loop:
        lb $t0, 0($a0) #load one byte from input
        lb $t1, 0($a1) #load one byte from the stored command

        li $t2, 65 #A
        li $t3, 90 #Z
        blt $t0, $t2, compare_char #do not convert it if its less than A
        bgt $t0, $t3, compare_char #do not convert it if its greater than Z
        addi $t0,$t0, 32 #converted to lower case        

     compare_char:
        bne $t0, $t1, not_equal 
        beqz $t0, equal   

        addi $a0, $a0,1 #next char
        addi $a1, $a1,1
        j loop

not_equal:
    li $v0, 1
    jr $ra

equal:
    li $v0, 0
    jr $ra

#int to string function #converts correctly ig
int_to_string:
    li $t1, 10           # divisor
    move $t2, $a1        # copy of our integer

    # Find the buffer end dynamically without using $t3 or $t4
    move $t6, $a0        # store start of buffer
    add $t7, $zero, 9    # max buffer size (assuming enough space)

    add $a0, $t6, $t7    # move to end of buffer
    sb $zero, 0($a0)     # add null terminator
    sub $a0, $a0, 1      # move left

convert_loop:
    divu $t2, $t1
    mfhi $t5             # get the last digit (using $t5 instead of $t3)
    mflo $t2

    addiu $t5, $t5, 48   # convert to ASCII
    sb $t5, 0($a0)       # store character
    sub $a0, $a0, 1      # move left

    bnez $t2, convert_loop

    addiu $a0, $a0, 1    # correct buffer pointer
    jr $ra


     
 # ------------------------------------

 #strcat function to connect the strings together !
 strcat: 
 #a0 is the destination while a1 is the source string
    move $t0, $a0 #the address

    find_end:
        lb $t1, 0($t0)
        beqz $t1, copy_str
        addiu $t0, $t0, 1
        j find_end

    copy_str: 
        lb $t1, 0($a1)
        beqz $t1, done
        sb $t1, 0($t0)
        addiu $t0, $t0, 1
        addiu $a1, $a1, 1
        j copy_str

     done:
         sb $zero, 0($t0)
         jr  $ra
    