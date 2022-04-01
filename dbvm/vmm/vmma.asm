BITS 64

;param passing in 64-bit (linux ABI, NOT windows)
;1=rdi
;2=rsi
;3=rdx
;4=rcx

extern vmm_entry
extern cinthandler
extern menu
extern memorylist
extern clearScreen

GLOBAL amain
GLOBAL vmmstart
GLOBAL pagedirptrvirtual
GLOBAL isAP
GLOBAL loadedOS
GLOBAL bootdisk
GLOBAL nakedcall
GLOBAL nextstack
GLOBAL _vmread
GLOBAL _vmwrite

GLOBAL _vmclear
GLOBAL _vmptrld
GLOBAL _vmxon
GLOBAL _vmxoff
GLOBAL _vmlaunch
GLOBAL _vmresume

GLOBAL getGDTbase
GLOBAL getIDTbase
GLOBAL getGDTsize
GLOBAL getIDTsize
GLOBAL setGDT
GLOBAL setIDT


%define VMCALL db 0x0f, 0x01, 0xc1 ;vmcall

;everything here is in virtual memory, paging has already been setup properly

GLOBAL _start
_start:
amain:

jmp short afterinitvariables
times 16-($-$$) db 0x90 ;pad with nop's till a nice 16-byte alignment



loadedOS:           dq 0 ;physical address of the loadedOS section
vmmstart:           dq 0 ;physical address of virtual address 00400000 (obsoletish...)
pagedirptrvirtual:  dq 0 ;virtual address of the pagedirptr (00400000+VMMSIZE+8192)


afterinitvariables:


mov rax,[nextstack] ;setup the stack
mov rsp,rax

and rsp,0xfffffffffffffff0


;sub rax,0x40000 ;256kb for the next cpu
sub rax,0x10000
mov [nextstack],rax


;wait2:
;mov edx,SERIALPORT+5 ;3fdh
;in al,dx
;and al,0x20
;cmp al,0x20
;jne wait2


;mov edx,SERIALPORT ;0x3f8
;mov al,'y'
;out dx,al

mov rax,cr4
or rax,0x200 ;enable fxsave
mov cr4,rax

call vmm_entry

vmm_entry_exit:
jmp vmm_entry_exit

dq 0
dq 0


align 16,db 0
isAP:              	dd 0
bootdisk:           dd 0
nextstack:		  	dq 0x00000000007FFFF8 ;start of stack for the next cpu



global vmcall_amd
vmcall_amd:
  vmmcall
  ret

global vmcall_intel
vmcall_intel:
  vmcall
  ret

global vmcall_instr
vmcall_instr: dq vmcall_intel

global vmcalltest_asm
vmcalltest_asm:
  sub rsp,8
  sub rsp,12

  mov dword [rsp],12
  mov dword [rsp+4],0xfedcba98
  mov dword [rsp+8],0

  ;xchg bx,bx
  mov rax,rsp
  mov rdx,0x76543210
  call [vmcall_instr]

  add rsp,8+12
  ret



global vmcall_setintredirects
vmcall_setintredirects:
;also int3 and int14
  sub rsp,8
  sub rsp,0x20

  mov dword [rsp],0x1c ;size of struct
  mov dword [rsp+4],0xfedcba98 ;p2
  mov dword [rsp+8],9 ;VMCALL_REDIRECTINT1

  mov dword [rsp+0xc],1 ;idt redirect instead of intredirect
  mov qword [rsp+0x14], inthandler1
  xor eax,eax
  mov ax,cs
  mov dword [rsp+0x1c], eax


   ;int3
  mov rax,rsp
  mov rdx,0x76543210 ;p1
  call [vmcall_instr]

  mov rax,rsp
  mov dword [rsp+8],24 ;VMCALL_REDIRECTINT3
  mov dword [rsp+0xc],1 ;idt redirect instead of intredirect
  mov qword [rsp+0x14], inthandler3
  call [vmcall_instr]

  mov rax,rsp
  mov dword [rsp+8],22 ;VMCALL_REDIRECTINT14
  mov dword [rsp+0xc],1 ;idt redirect instead of intredirect
  mov qword [rsp+0x14], inthandler14
  call [vmcall_instr]


  add rsp,8+0x20
  ret

global SaveExtraHostState
;void SaveExtraHostState(VMCB_PA)
SaveExtraHostState:
  ;xchg bx,bx
  xchg rax,rdi
  vmsave
  xchg rax,rdi
  ret

struc vmxloop_amd_stackframe
  saved_r15:      resq 1
  saved_r14:      resq 1
  saved_r13:      resq 1
  saved_r12:      resq 1
  saved_r11:      resq 1
  saved_r10:      resq 1
  saved_r9:       resq 1
  saved_r8:       resq 1
  saved_rbp:      resq 1
  saved_rsi:      resq 1
  saved_rdi:      resq 1
  saved_rdx:      resq 1
  saved_rcx:      resq 1
  saved_rbx:      resq 1
  saved_rax:      resq 1
                  resq 1  ;alignment
  fxsavespace:    resb 512 ;fxsavespace must be aligned
  psavedstate:    resq 1 ;saved param3
  vmcb_PA:        resq 1 ;saved param2
  currentcpuinfo: resq 1 ;saved param1
  ;At entry RSP points here
  returnaddress:  resq 1


endstruc
extern vmexit_amd

align 16
global vmxloop_amd
vmxloop_amd:
;xchg bx,bx ;break by bochs

sub rsp, vmxloop_amd_stackframe_size-8 ;-8 because the structure assumes returnaddress is in

mov [rsp+currentcpuinfo],rdi
mov [rsp+vmcb_PA], rsi
mov [rsp+psavedstate], rdx

clgi ;no more interrupts from this point on. (Not even some special interrupts)


mov rax,rdx
cmp rax,0
je notloadedos_amd

;setup the initial state
mov rbx,[rax+0x08]
mov rcx,[rax+0x10]
mov rdx,[rax+0x18]
mov rsi,[rax+0x20]
mov rdi,[rax+0x28]
mov rbp,[rax+0x30]
mov r8,[rax+0x40]
mov r9,[rax+0x48]
mov r10,[rax+0x50]
mov r11,[rax+0x58]
mov r12,[rax+0x60]
mov r13,[rax+0x68]
mov r14,[rax+0x70]
mov r15,[rax+0x78]

jmp vmrun_loop


notloadedos_amd:
;init to startup state (or offloados state)

xor rax,rax
mov rbx,rax
mov rcx,rax
mov rdx,rax
mov rdi,rax
mov rbp,rax
mov r8, rax
mov r9, rax
mov r10,rax
mov r11,rax
mov r12,rax
mov r13,rax
mov r14,rax
mov r15,rax
mov rsi,rax


vmrun_loop:
;xchg bx,bx
mov rax,[rsp+vmcb_PA]  ;for those wondering, RAX is stored in the vmcb->RAX field, not here
vmload
vmrun ;rax
vmsave


;on return RAX and RSP are unchanged, but ALL other registers are changed and MUST be saved first
;xchg bx,bx

fxsave [rsp+fxsavespace]
mov [rsp+saved_r15],r15
mov [rsp+saved_r14],r14
mov [rsp+saved_r13],r13
mov [rsp+saved_r12],r12
mov [rsp+saved_r11],r11
mov [rsp+saved_r10],r10
mov [rsp+saved_r9],r9
mov [rsp+saved_r8],r8
mov [rsp+saved_rbp],rbp
mov [rsp+saved_rsi],rsi
mov [rsp+saved_rdi],rdi
mov [rsp+saved_rdx],rdx
mov [rsp+saved_rcx],rcx
mov [rsp+saved_rbx],rbx
mov [rsp+saved_rax],rax

mov rdi,[rsp+currentcpuinfo]
lea rsi,[rsp+saved_r15] ;vmregisters

call vmexit_amd

;check return. If everything ok restore and jump to vmrun_loop
cmp eax,1
je vmrun_exit

;restore
fxrstor [rsp+fxsavespace]
mov r15,[rsp+saved_r15]
mov r14,[rsp+saved_r14]
mov r13,[rsp+saved_r13]
mov r12,[rsp+saved_r12]
mov r11,[rsp+saved_r11]
mov r10,[rsp+saved_r10]
mov r9,[rsp+saved_r9]
mov r8,[rsp+saved_r8]
mov rbp,[rsp+saved_rbp]
mov rsi,[rsp+saved_rsi]
mov rdi,[rsp+saved_rdi]
mov rdx,[rsp+saved_rdx]
mov rcx,[rsp+saved_rcx]
mov rbx,[rsp+saved_rbx]


jmp vmrun_loop



vmrun_exit:
add rsp,vmxloop_amd_stackframe_size-8
ret


global vmxloop
extern vmexit
;-------------------------;
;int vmxloop(cpuinfo *cpu, UINT64 *rax);
;-------------------------;
vmxloop: ;esp=return address, edi = cpuinfo structure pointer, rsi=mapped loadedOS eax base
;0


pushfq   ;8

push rax ;16
push rbx ;24
push rcx ;32
push rdx ;40
push rdi ;48
push rsi ;56
push rbp ;64
push r8  ;72
push r9  ;80
push r10 ;88
push r11 ;96
push r12 ;112
push r13 ;120
push r14 ;128
push r15 ;136

mov rax,0x6c14
vmwrite rax,rsp ;host_esp

mov rax,0x6c16
mov rdx,vmxloop_vmexit
vmwrite rax,rdx  ;host_eip

cmp DWORD [loadedOS],0
je notloadedOS

osoffload:
;xchg bx,bx
mov rax,[rsi]
mov rbx,[rsi+0x08]
mov rcx,[rsi+0x10]
mov rdx,[rsi+0x18]
mov rdi,[rsi+0x28]
mov rbp,[rsi+0x30]
mov r8,[rsi+0x40]
mov r9,[rsi+0x48]
mov r10,[rsi+0x50]
mov r11,[rsi+0x58]
mov r12,[rsi+0x60]
mov r13,[rsi+0x68]
mov r14,[rsi+0x70]
mov r15,[rsi+0x78]

mov rsi,[rsi+0x20]

jmp aftersetup

notloadedOS:
xor rax,rax
mov rbx,rax
mov rcx,rax
mov rdx,rax
mov rdi,rax
mov rsi,rax
mov rbp,rax
mov r8, rax
mov r9, rax
mov r10,rax
mov r11,rax
mov r12,rax
mov r13,rax
mov r14,rax
mov r15,rax

aftersetup:
vmlaunch
;just continued through, restore state
nop
nop ;just making sure as for some reason kvm's gdb continues here, instead of the previous instruction
nop

pop r15 ;128
pop r14
pop r13
pop r12
pop r11
pop r10
pop r9
pop r8
pop rbp
pop rsi
pop rdi
pop rdx
pop rcx
pop rbx
pop rax ;8

jc vmxloop_fullerr
jz vmxloop_halferr
jmp vmxloop_weirderr


vmxloop_fullerr:
mov eax,1
popfq ;(esp-0)
ret

vmxloop_halferr:
mov eax,2
popfq ;(esp-0)
ret

vmxloop_weirderr:
mov eax,3
popfq ;(esp-0)
ret

align 16
vmxloop_vmexit:
cli
;ok, this should be executed

;save registers

sub rsp,15*8

mov [rsp],r15
mov [rsp+1*8],r14
mov [rsp+2*8],r13
mov [rsp+3*8],r12
mov [rsp+4*8],r11
mov [rsp+5*8],r10
mov [rsp+6*8],r9
mov [rsp+7*8],r8
mov [rsp+8*8],rbp
mov [rsp+9*8],rsi
mov [rsp+10*8],rdi
mov [rsp+11*8],rdx
mov [rsp+12*8],rcx
mov [rsp+13*8],rbx
mov [rsp+14*8],rax

;set host into a 'valid' state
mov rbp,rsp


fucker:
mov rdi,[rbp+128+ 72] ; param1:currentcpuinfo (rdi of the original host registers, so past the guest registers, inside the host save state)
mov rsi,rbp ; param2: pointer to the guest registers (stored on stack)

cmp rdi,0
jne notfucker

;xchg bx,bx
wbinvd

mov rbx,0x681e
vmread rax,rbx

mov rbx,0x6808
vmread rbx,rbx



mov rdi,[rsp+128+ 72] ; param1:currentcpuinfo (rdi of the original host registers, so past the guest registers, inside the host save state)
mov rsi,rsp ; param2: pointer to the guest registers (stored on stack)


notfucker:
;sub rbp,8

;xchg bx,bx ;boxhs bp

and rsp,0xfffffffffffffff0;
sub rsp,512
fxsave [rsp]

sub rsp,32

;xchg bx,bx

call vmexit

add rsp,32
fxrstor [rsp]


mov rsp,rbp


cmp eax,1  ;returnvalue of 1 = quit vmx
jae vmxloop_exitvm
;returned 0, so


;restore vmx registers (esp-36)
pop r15
pop r14
pop r13
pop r12
pop r11
pop r10
pop r9
pop r8
pop rbp
pop rsi
pop rdi
pop rdx
pop rcx
pop rbx
pop rax

;and resume
vmresume

;never executed unless on error
;restore state of vmm
mov rax,3
jmp vmxloop_exit

vmxloop_exitvm:  ;(esp-68)
;user quit or couldn't be handled
xor eax,eax  ;0, so ok



vmxloop_exit: ;(esp)
add rsp,120  ;128=eax=eflags=error, 136=ebx=eflags, 120=
pop r15
pop r14
pop r13
pop r12
pop r11
pop r10
pop r9
pop r8
pop rbp
pop rsi
pop rdi
pop rdx
pop rcx
pop rbx
add rsp,8 ;;skip rax, rax contains the result
popfq ;restore flags (esp)
ret

db 0xcc
db 0xcc
db 0xcc

;---------------------;
;void setRFLAGS(void);
;---------------------;
global setRFLAGS
setRFLAGS:
push rdi
popfq
ret
;---------------------;
;ULONG getRFLAGS(void);
;---------------------;
global getRFLAGS
getRFLAGS:
pushfq
pop rax
ret

db 0xcc
db 0xcc
db 0xcc

;-----------------------------------;
;void setIDT(UINT64 base, WORD size);
;-----------------------------------;
setIDT:
push rbp
mov rbp,rsp
sub rbp,20

mov [rbp],si
mov [rbp+2],rdi
lidt [rbp]

pop rbp
ret

db 0xcc
db 0xcc
db 0xcc
;-----------------------------------;
;void setGDT(UINT64 base, WORD size);
;-----------------------------------;
setGDT:
push rbp
mov rbp,rsp
sub rbp,20

mov [rbp],si
mov [rbp+2],rdi
lgdt [rbp]

pop rbp
ret

db 0xcc
db 0xcc
db 0xcc

;----------------------;
;WORD getGDTsize(void);
;----------------------;
getGDTsize:
push rbp
mov rbp,rsp
sub rbp,20
sgdt [rbp]
xor ax,ax
mov ax,[rbp]
pop rbp
ret

db 0xcc
db 0xcc
db 0xcc

;----------------------;
;WORD getIDTsize(void);
;----------------------;
getIDTsize:
push rbp
mov rbp,rsp
sub rbp,20
sidt [rbp]
xor ax,ax
mov ax,[rbp]
pop rbp
ret

db 0xcc
db 0xcc
db 0xcc

;----------------------;
;ULONG getGDTbase(void);
;----------------------;
getGDTbase:
push rbp
mov rbp,rsp
sub rbp,20
sgdt [rbp]
mov rax,[rbp+2]
pop rbp
ret

db 0xcc
db 0xcc
db 0xcc

;----------------------;
;ULONG getIDTbase(void);
;----------------------;
getIDTbase:
push rbp
mov rbp,rsp
sub rbp,20
sidt [rbp]
mov rax,[rbp+2]
pop rbp
ret

db 0xcc
db 0xcc
db 0xcc

;--------------------------;
;WORD getTaskRegister(void);
;--------------------------;
GLOBAL getTaskRegister
getTaskRegister:
str ax
ret

;-------------------------------------;
;void loadTaskRegister(ULONG selector);
;-------------------------------------;
GLOBAL loadTaskRegister
loadTaskRegister:
mov ax,di
ltr ax
ret

db 0xcc
db 0xcc
db 0xcc
;---------------------------;
;UINT64 _vmread(ULONG index);
;---------------------------;
_vmread:
vmread rax,rdi
ret
db 0xcc
db 0xcc
db 0xcc
;---------------------------------------;
;void _vmwrite(ULONG index,UINT64 value);
;---------------------------------------;
_vmwrite:
vmwrite rdi,rsi
ret
db 0xcc
db 0xcc
db 0xcc

;---------------------------------------;
;int vmclear(unsigned long long address);
;---------------------------------------;
_vmclear:
push rdi
vmclear [rsp]
pop rdi
jc vmclear_err
xor rax,rax
ret
db 0xcc
db 0xcc
db 0xcc

vmclear_err:
mov rax,1
ret
db 0xcc
db 0xcc
db 0xcc

;-------------------------------------;
;int vmptrld(PHYSICAL_ADDRESS address);
;-------------------------------------;
_vmptrld:
push rdi
vmptrld [rsp]
pop rdi
jc vmptrld_err
xor rax,rax
ret
db 0xcc
db 0xcc
db 0xcc

vmptrld_err:
mov rax,1
ret
db 0xcc
db 0xcc
db 0xcc

;-----------------------------------;
;int vmxon(PHYSICAL_ADDRESS address);
;-----------------------------------;
_vmxon:
push rdi
vmxon [rsp]				 ;vmxon [eax]
pop rdi

jc vmxon_err
xor rax,rax
ret
db 0xcc
db 0xcc
db 0xcc

vmxon_err:
mov rax,1
ret
db 0xcc
db 0xcc
db 0xcc

;-----------------;
;void vmxoff(void);
;-----------------;
_vmxoff:
vmxoff
ret
db 0xcc
db 0xcc
db 0xcc

;------------------;
;int vmlaunch(void);
;------------------;
_vmlaunch:
;setup the launch registers
mov eax,0
mov ebx,0
mov ecx,0
mov edx,0xf00
mov edi,0
mov esi,0
vmlaunch
jc vmlaunch_err
jz vmlaunch_err_half
xor eax,eax
ret
db 0xcc
db 0xcc
db 0xcc

vmlaunch_err:
mov eax,1
ret
db 0xcc
db 0xcc
db 0xcc

vmlaunch_err_half:
mov eax,2
ret
db 0xcc
db 0xcc
db 0xcc

;-------------------;
;void vmresume(void);
;-------------------;
_vmresume:
vmresume
ret ;not really needed...
db 0xcc
db 0xcc
db 0xcc

;-------------------------------------;
;unsigned long long readMSR(ULONG msr);
;-------------------------------------;
global readMSR
readMSR:
xchg ecx,edi
rdmsr ;return goes into edx:eax , which just so happens to be the needed value
shl rdx,32
add rax,rdx
xchg ecx,edi
ret
db 0xcc
db 0xcc
db 0xcc

;-------------------------------------;
;unsigned long long writeMSR(ULONG msr, unsigned long long newvalue);
;-------------------------------------;
global writeMSR
writeMSR:

push rcx
push rax
push rdx
mov ecx,edi
mov eax,esi
mov rdx,rsi
shr rdx,32

wrmsr
pop rdx
pop rax
pop rcx
ret
db 0xcc
db 0xcc
db 0xcc

;------------------------------------;
;void xsetbv(ULONG xcr, UINT64 value);
;------------------------------------;
global _xsetbv
_xsetbv:
push rcx
push rax
push rdx
mov ecx,edi
mov eax,esi
mov rdx,rsi
shr rdx,32

xsetbv

pop rdx
pop rax
pop rcx
ret
db 0xcc
db 0xcc
db 0xcc


;----------------;
;int3bptest(void);
;----------------;
global int3bptest
int3bptest:
nop
nop
db 0x66
db 0x67
db 0xcc
nop
nop
ret

;-------------------;
;void testcode(int x);
;-------------------;
global testcode
testcode:
mov rax,rdi
nop
nop
nop
cmp rax,rdi
jne testcode_end
nop
nop
testcode_end:
nop
nop
nop

;popad
ret
db 0xcc
db 0xcc
db 0xcc



global hascpuid
;------------------;
;int hascpuid(void);
;------------------;
hascpuid:
push rdx

pushfq
pop rax
mov rdx,rax

xor rax,1000000000000000000000b
push rax
popfq
pushfq
pop rax
cmp rax,rdx
pop rdx

je hascpuid_no ;same as original (unchanged)
mov rax,1
ret
db 0xcc
db 0xcc
db 0xcc

hascpuid_no:
xor rax,rax
ret
db 0xcc
db 0xcc
db 0xcc

global stopautomation
;-------------------------;
;void stopautomation(void);
;-------------------------;
stopautomation:
mov rax,0xcececece
VMCALL
ret
db 0xcc
db 0xcc
db 0xcc


global cLIDT
;----------------------;
;cLIDT(void *idtloader);
;----------------------;
cLIDT:
;rdi contains the address of the new idt descriptor
lidt [rdi]
ret
db 0xcc
db 0xcc
db 0xcc

global getCR0
;------------;
;ULONG getCR0(void);
;------------;
getCR0:
mov rax,cr0
ret
db 0xcc
db 0xcc
db 0xcc

global setCR0
;--------------------;
;setCR0(ULONG newcr0);
;--------------------;
setCR0:
mov cr0,rdi
ret
db 0xcc
db 0xcc
db 0xcc




global getCR2
;------------;
;UINT64 getCR2(void);
;------------;
getCR2:
mov rax,cr2
ret
db 0xcc
db 0xcc
db 0xcc

global setCR2
;--------------------;
;setCR2(UINT64 newcr2);
;--------------------;
setCR2:
mov cr2,rdi
ret
db 0xcc
db 0xcc
db 0xcc

global setCR3
;------------;
;setCR3(UINT64 newcr3);
;------------;
setCR3:
mov cr3,rdi
ret
db 0xcc
db 0xcc
db 0xcc

global getCR3
;------------;
;ULONG getCR3(void);
;------------;
getCR3:
mov rax,cr3
ret
db 0xcc
db 0xcc
db 0xcc

global getCR4
;------------------;
;ULONG getCR4(void);
;------------------;
getCR4:
mov rax,cr4
ret
db 0xcc
db 0xcc
db 0xcc

global setCR4
;--------------------;
;setCR4(ULONG newcr4);
;--------------------;
setCR4:
mov cr4,rdi
ret
db 0xcc
db 0xcc
db 0xcc


global getDR0
;------------------;
;ULONG getDR0(void);
;------------------;
getDR0:
mov rax,dr0
ret
db 0xcc
db 0xcc
db 0xcc


global setDR0
;--------------------;
;setDR0(ULONG newdr0);
;--------------------;
setDR0:
mov dr0,rdi
ret
db 0xcc
db 0xcc
db 0xcc


global getDR1
;------------------;
;ULONG getDR1(void);
;------------------;
getDR1:
mov rax,dr1
ret
db 0xcc
db 0xcc
db 0xcc

global getDR2
;------------------;
;ULONG getDR2(void);
;------------------;
getDR2:
mov rax,dr2
ret
db 0xcc
db 0xcc
db 0xcc

global getDR3
;------------------;
;ULONG getDR3(void);
;------------------;
getDR3:
mov rax,dr3
ret
db 0xcc
db 0xcc
db 0xcc

global getDR6
;------------------;
;ULONG getDR6(void);
;------------------;
getDR6:
mov rax,dr6
ret
db 0xcc
db 0xcc
db 0xcc

global setDR6
;--------------------;
;setDR6(UINT64 newdr6);
;--------------------;
setDR6:
mov dr6,rdi
ret
db 0xcc
db 0xcc
db 0xcc

global getDR7
;------------------;
;ULONG getDR7(void);
;------------------;
getDR7:
mov rax,dr7
ret
db 0xcc
db 0xcc
db 0xcc

global setDR7
;--------------------;
;setDR7(UINT64 newdr7);
;--------------------;
setDR7:
mov dr7,rdi
ret
db 0xcc
db 0xcc
db 0xcc


global _invlpg
;-----------------------;
;_invlpg(UINT64 address);
;-----------------------;
_invlpg:
invlpg [rdi]
ret
db 0xcc
db 0xcc
db 0xcc


global _rdtsc
;-------------------------------;
;unsigned long long _rdtsc(void);
;-------------------------------;
_rdtsc:
rdtsc
shl rdx,32
add rax,rdx
ret
db 0xcc
db 0xcc
db 0xcc

global _pause
;-------------------------------;
;void _pause(void);
;-------------------------------;
_pause:
nop
nop
nop
pause
nop
nop
nop
ret
db 0xcc
db 0xcc
db 0xcc



%macro	_inthandler	1
global inthandler%1
inthandler%1:
;xchg bx,bx

cli ;is probably already done, but just to be sure
push %1
jmp inthandlerx
db 0xcc
db 0xcc
db 0xcc
%endmacro


inthandlerx: ;called by the _inthandler macro after it has set it's int nr
push rax ;8
push rbx ;16
push rcx ;24
push rdx ;32
push rdi ;
push rsi ;
push rbp ;
push r8  ;64
push r9  ;
push r10 ;
push r11 ;
push r12 ;
push r13 ;
push r14 ;
push r15 ;128

mov rsi,[rsp+120] ;param2 (intnr)
mov rdi,rsp ;param1 (stack)

mov rbp,rsp
and rsp,0xfffffffffffffff0
sub rsp,32

call cinthandler

mov rsp,rbp


pop r15
pop r14
pop r13
pop r12
pop r11
pop r10
pop r9
pop r8
pop rbp
pop rsi
pop rdi
pop rdx
pop rcx
pop rbx

cmp rax,0
pop rax
je inthandlerx_noerrorcode

;errocode
add rsp,16 ;undo push (intnr) and errorcode
jmp inthandlerx_exit

inthandlerx_noerrorcode:
add rsp,8  ;undo push (intnr)

inthandlerx_exit:
iretq



db 0xcc
db 0xcc
db 0xcc

_inthandler 0
_inthandler 1
_inthandler 2
_inthandler 3
_inthandler 4
_inthandler 5
_inthandler 6
_inthandler 7
_inthandler 8
_inthandler 9
_inthandler 10
_inthandler 11
_inthandler 12
_inthandler 13
_inthandler 14
_inthandler 15
_inthandler 16
_inthandler 17
_inthandler 18
_inthandler 19
_inthandler 20
_inthandler 21
_inthandler 22
_inthandler 23
_inthandler 24
_inthandler 25
_inthandler 26
_inthandler 27
_inthandler 28
_inthandler 29
_inthandler 30
_inthandler 31
_inthandler 32
_inthandler 33
_inthandler 34
_inthandler 35
_inthandler 36
_inthandler 37
_inthandler 38
_inthandler 39
_inthandler 40
_inthandler 41
_inthandler 42
_inthandler 43
_inthandler 44
_inthandler 45
_inthandler 46
_inthandler 47
_inthandler 48
_inthandler 49
_inthandler 50
_inthandler 51
_inthandler 52
_inthandler 53
_inthandler 54
_inthandler 55
_inthandler 56
_inthandler 57
_inthandler 58
_inthandler 59
_inthandler 60
_inthandler 61
_inthandler 62
_inthandler 63
_inthandler 64
_inthandler 65
_inthandler 66
_inthandler 67
_inthandler 68
_inthandler 69
_inthandler 70
_inthandler 71
_inthandler 72
_inthandler 73
_inthandler 74
_inthandler 75
_inthandler 76
_inthandler 77
_inthandler 78
_inthandler 79
_inthandler 80
_inthandler 81
_inthandler 82
_inthandler 83
_inthandler 84
_inthandler 85
_inthandler 86
_inthandler 87
_inthandler 88
_inthandler 89
_inthandler 90
_inthandler 91
_inthandler 92
_inthandler 93
_inthandler 94
_inthandler 95
_inthandler 96
_inthandler 97
_inthandler 98
_inthandler 99
_inthandler 100
_inthandler 101
_inthandler 102
_inthandler 103
_inthandler 104
_inthandler 105
_inthandler 106
_inthandler 107
_inthandler 108
_inthandler 109
_inthandler 110
_inthandler 111
_inthandler 112
_inthandler 113
_inthandler 114
_inthandler 115
_inthandler 116
_inthandler 117
_inthandler 118
_inthandler 119
_inthandler 120
_inthandler 121
_inthandler 122
_inthandler 123
_inthandler 124
_inthandler 125
_inthandler 126
_inthandler 127
_inthandler 128
_inthandler 129
_inthandler 130
_inthandler 131
_inthandler 132
_inthandler 133
_inthandler 134
_inthandler 135
_inthandler 136
_inthandler 137
_inthandler 138
_inthandler 139
_inthandler 140
_inthandler 141
_inthandler 142
_inthandler 143
_inthandler 144
_inthandler 145
_inthandler 146
_inthandler 147
_inthandler 148
_inthandler 149
_inthandler 150
_inthandler 151
_inthandler 152
_inthandler 153
_inthandler 154
_inthandler 155
_inthandler 156
_inthandler 157
_inthandler 158
_inthandler 159
_inthandler 160
_inthandler 161
_inthandler 162
_inthandler 163
_inthandler 164
_inthandler 165
_inthandler 166
_inthandler 167
_inthandler 168
_inthandler 169
_inthandler 170
_inthandler 171
_inthandler 172
_inthandler 173
_inthandler 174
_inthandler 175
_inthandler 176
_inthandler 177
_inthandler 178
_inthandler 179
_inthandler 180
_inthandler 181
_inthandler 182
_inthandler 183
_inthandler 184
_inthandler 185
_inthandler 186
_inthandler 187
_inthandler 188
_inthandler 189
_inthandler 190
_inthandler 191
_inthandler 192
_inthandler 193
_inthandler 194
_inthandler 195
_inthandler 196
_inthandler 197
_inthandler 198
_inthandler 199
_inthandler 200
_inthandler 201
_inthandler 202
_inthandler 203
_inthandler 204
_inthandler 205
_inthandler 206
_inthandler 207
_inthandler 208
_inthandler 209
_inthandler 210
_inthandler 211
_inthandler 212
_inthandler 213
_inthandler 214
_inthandler 215
_inthandler 216
_inthandler 217
_inthandler 218
_inthandler 219
_inthandler 220
_inthandler 221
_inthandler 222
_inthandler 223
_inthandler 224
_inthandler 225
_inthandler 226
_inthandler 227
_inthandler 228
_inthandler 229
_inthandler 230
_inthandler 231
_inthandler 232
_inthandler 233
_inthandler 234
_inthandler 235
_inthandler 236
_inthandler 237
_inthandler 238
_inthandler 239
_inthandler 240
_inthandler 241
_inthandler 242
_inthandler 243
_inthandler 244
_inthandler 245
_inthandler 246
_inthandler 247
_inthandler 248
_inthandler 249
_inthandler 250
_inthandler 251
_inthandler 252
_inthandler 253
_inthandler 254
_inthandler 255

tester:
mov al,1
lp:
mov byte [0x0b8000],'Y'
mov byte [0x0b8001],al
inc al
mov byte [0x0b8002],'o'
mov byte [0x0b8003],al
inc al
mov byte [0x0b8004],'u'
mov byte [0x0b8005],al
inc al
mov byte [0x0b8006],' '
mov byte [0x0b8007],al
inc al
mov byte [0x0b8008],'R'
mov byte [0x0b8009],al
inc al
mov byte [0x0b800a],'o'
mov byte [0x0b800b],al
inc al
mov byte [0x0b800c],'c'
mov byte [0x0b800d],al
inc al
mov byte [0x0b800e],'k'
mov byte [0x0b800f],al
inc al
jmp lp


;---------------------;
;void changetask(void);
;---------------------;
global changetask
changetask:
nop
nop
bits 32
call 64:0
bits 64
nop
nop

ret

;-------------------;
;void tasktest(void);
;-------------------;
global tasktest
tasktest:
pushfq
pop rax
and rax,0x10000
cmp rax,0x10000
je tasktest_RF

mov byte [0xb8000],'B';
mov byte [0xb8002],'L';
mov byte [0xb8004],'A';
jmp tasktest_return

tasktest_RF:
mov byte [0xb8000],'R';
mov byte [0xb8002],'F';
mov byte [0xb8004],'1';

tasktest_return:
nop
nop
nop
nop
nop
iret
nop
nop
jmp tasktest


bits 64
global virtual8086_start
;----------------------------;
;void virtual8086_start(void);
;----------------------------;
virtual8086_start:
;called from 64-bit, so still in 64-bit mode



jmp far [moveto32bitstart]

global moveto32bitstart
moveto32bitstart:
dd 0x2000
dw 24

bits 32
global virtual8086entry32bit
virtual8086entry32bit:
;this gets moved to 0x2000


mov byte [0xb8000],'1';
mov byte [0xb8001],15;

;disable paging
mov eax,cr0
and eax,0x7FFFFFFF
mov cr0,eax

xor eax,eax
mov cr3,eax

mov byte [0xb8000],'2';
mov byte [0xb8001],15;



;unset IA32_EFER_LME to 0 (disable 64 bits)
mov ecx,0xc0000080
rdmsr
and eax,0xFFFFFEFF
wrmsr


mov eax,cr4
or eax,1
mov cr4,eax

mov byte [0xb8000],'3';
mov byte [0xb8001],15;


;xchg bx,bx
mov word [0x40000],0x4f
mov eax,[0x3004]
mov dword [0x40002],eax
lgdt [0x40000]


mov byte [0xb8000],'4';
mov byte [0xb8001],15;



;xchg bx,bx
;xor eax,eax
;mov cr0,eax
jmp (4*8):(0x2000+entry16-virtual8086entry32bit)

bits 16

entry16:
xor eax,eax
mov cr0,eax
jmp 0:(0x2000+realmodetest-virtual8086entry32bit)


;mov eax,[0x3000]
;mov cr3,eax
;mov eax,cr0
;or eax,0x80000000 ;enable paging
;mov cr0,eax
;jmp virtual8086entry32bit2

;virtual8086entry32bit2:

bits 32
nop
mov ax,8
mov ds,ax
mov es,ax
mov fs,ax
mov gs,ax
mov ss,ax

;mov byte [0xdead],1

mov word [0x40008],256*8
mov eax,[0x3008] ;idt table
mov dword [0x4000a],eax
lidt [0x40008]

mov ax,56
ltr ax
nop
nop
nop
jmp 64:0

notcrashed:
jmp notcrashed

;global idttable32
;idttable32:
;times 256*8 db 0   ; Make space


global inthandler_32
inthandler_32:
;protected mode interrupt
push ebp
mov ebp,esp

;ebp+0x0=old ebp
;ebp+0x4=intnr
;ebp+0x8=eip
;ebp+0xc=cs
;ebp+0x10=eflags
;ebp+0x14=esp
;ebp+0x18=ss
pushfd
push ebx
push eax
push ds
mov ax,8
mov ds,ax

;save state in realmode stack
sub word [ebp+0x14],6 ;decrease stack with 6 (3 pushes)

xor eax,eax
xor ebx,ebx
mov ax,[ebp+0x18] ;ss
mov bx,[ebp+0x14] ;sp
shl eax,4
add eax,ebx

;eax now contains the stack address in realmode
mov bx,[ebp+8]
mov [eax],bx ;save ip
mov bx,[ebp+0xc]
mov [eax+2],bx ;save cs
mov bx,[ebp+0x10]
mov [eax+4],bx ;save eflags


;change return link
mov eax,[ebp+4] ;eax gets the intnr
mov bx,word [eax*4]   ;ip
mov ax,word [eax*4+2] ;cs
mov [ebp+0x8],bx
mov [ebp+0xc],ax
pop ds
pop eax
pop ebx
popfd
pop ebp
add esp,4 ;get rid of push intnr
iret

bits 16
global realmodetest
realmodetest:

xor eax,eax
mov cr0,eax
mov cr3,eax
mov cr4,eax

xor eax,eax
xor ebx,ebx
xor ecx,ecx
xor edx,edx
xor esi,esi
xor edi,edi
xor ebp,ebp
xor esp,esp





mov ax,0xb800
mov ds,ax
mov byte [ds:0],'5'
mov byte [ds:1],15

jmp 0:(0x2000+realmodetest_b-virtual8086entry32bit)
realmodetest_b:

mov ax,0xb800
mov ds,ax
mov byte [ds:0],'6'
mov byte [ds:1],15


mov ax,0x8000
mov ds,ax
mov es,ax
mov word [0],0x400   ;  256*4
mov dword [2],0
lidt [0x0]

mov word [0],0   ;  0
mov dword [2],0
lgdt [0x0]


nop
nop
nop
xor ax,ax
mov ds,ax
mov es,ax
mov fs,ax
mov gs,ax
mov ax,0x4000
mov ss,ax
mov sp,0xff00
nop
nop
nop
cli
nop

mov ax,0xb800
mov ds,ax
mov byte [ds:0],'7'
mov byte [ds:1],15

;call 0xc000:0000



mov ah,0
mov al,3
int 10h


mov ax,0xb800
mov ds,ax
mov byte [ds:0],'8'
mov byte [ds:1],15

;at 80x25 now

showpsod:
xchg bx,bx
cld
mov ax,0b800h
mov si,0
mov di,0
mov ds,ax
mov es,ax
mov cx,(80*25)
mov ax,05000h  ;pink background, black text
rep stosw

;write the message (stored at 40000h)

mov ax,06000h
mov ds,ax
mov si,0
mov di,0

psod_loop:
cmp byte [ds:si],0
je psod_lock ;reached end

cmp byte [ds:si],10
je newline

cmp byte [ds:si],13
je newline

jmp nonewline

newline:
xor dx,dx
add di,80*2
mov ax,di
mov cx,80*2
div cx
sub di,dx

add si,1
jmp psod_loop


;newline

nonewline:
mov al,[ds:si]
mov [es:di],al

add si,1
add di,2

jmp psod_loop


psod_lock:
jmp psod_lock



bits 64

;--------------------;
;void infloop(void);
;--------------------;
global infloop
infloop:
nop
nop
xchg bx,bx
nop
hlt
nop
nop
xchg bx,bx ;should never happen
nop
jmp infloop


;--------------------;
;void quickboot(void);
;--------------------;
global quickboot
quickboot:
;quickboot is called by the virtual machine as initial boot startup
call clearScreen


;nop
;nop
;xchg bx,bx
;mov eax,0
;push 0x197
;popfq
;cpuid
;nop
;nop

;disable cpuid bit
pushfq
pop rax
and rax,0xFFDFF32A
or rax,0x80
push rax
popfq

;clean some unused 64-bit registers
xor r8,r8
xor r9,r9
xor r10,r10
xor r11,r11
xor r12,r12
xor r13,r13
xor r14,r14
xor r15,r15

mov word [0x40000],0x3f
mov dword [0x40002],0x50000
lgdt [0x40000]

jmp far [movetorealstart]

movetorealstart:
dd 0x00020000
dw 24

global movetoreal
global movetoreal_end
bits 32
movetoreal: ;this gets moved to 0x00020000
nop
nop
nop


mov ax,8
mov ds,ax
mov es,ax
mov fs,ax
mov gs,ax
mov ss,ax
mov esp,0x5000
mov eax,0
cpuid

;disable paging
mov eax,cr0
and eax,0x7FFFFFFF
mov cr0,eax

xor eax,eax
mov cr3,eax

;unset IA32_EFER_LME to 0 (disable 64 bits)
mov ecx,0xc0000080
rdmsr
and eax,0xFFFFFEFF
wrmsr
nop



;mov byte [0x1dead],2
nop
nop

;go to 16 bit
jmp 32:0x0000+(real16-movetoreal)

global real16
real16:
bits 16
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
;setup datasegment, just for the fun of it
mov ax,40
mov ds,ax
mov es,ax
mov fs,ax
mov gs,ax
mov ss,ax

xor eax,eax
mov cr0,eax
nop

jmp realmode

global realmode
realmode:
mov ax,0x8000
mov ss,ax
mov sp,0xfffe

rmstart:
call rmbegin
rmbegin:
pop bp


push 0x2000
push vmxstartup-movetoreal
iret


rmmarker:
dw 0x0000+(vmxstartup-movetoreal)
dw 0x2000

;still 16 bits here
;---------------------;
;void vmxstartup(void);  (should be at 0x20000 when executed)
;---------------------;
global vmxstartup
global vmxstartup_end
vmxstartup:
nop

mov ax,0xb800
mov ds,ax
mov byte [0],'w';
mov byte [1],4;
mov byte [2],'e';
mov byte [3],4;
mov byte [4],'e';
mov byte [5],4;
mov byte [6],'e';
mov byte [7],4;


mov ax,0x8000
mov ds,ax
mov es,ax
mov word [0],0x400   ;  256*4
mov dword [2],0
lidt [0x0]

mov word [0],0   ;  0
mov dword [2],0
lgdt [0x0]


;xchg bx,bx
nop
mov ecx,0xc0000080 ;test to see how it handles an efer write
xor eax,eax
xor edx,edx
;wrmsr

nop
;xchg bx,bx
nop

;mov ecx,0xc0010117 ;cause an exit
;rdmsr


xor eax,eax
xor ebx,ebx
xor ecx,ecx
xor edx,edx
xor ebp,ebp
xor edi,edi
xor esi,esi
mov cr4,eax
nop
nop
nop

mov ax,0x1234
mov eax,CR0

mov bx,0x2345
mov ebx,CR0

vm_basicinit:
cli  ;not be needed, but it's a way to break the vm
;xchg bx,bx

xor ax,ax
mov ds,ax
mov es,ax
mov fs,ax
mov gs,ax
mov ax,0x7000
mov ss,ax
mov sp,0x8000

mov eax,[0x7dfa] ;restore cr0 with the stored value of cr0
mov cr0,eax
;jmp 0:0x7c00

vm_readagain:
nop
nop
cld

sti

mov byte [0x7c00],1

;loopy:
;jmp loopy

hwtest:
nop
nop
nop

;mov byte [0x7c0e],0x80

mov ax,0x3000
mov es,ax

mov ax,0
mov dl,[0x7c0e]
clc
int 0x13
jc notok
nop
nop
mov ax,0
mov dl,[0x7c0e]
clc
int 0x13
jc notok
nop
nop
nop
mov ax,0x0201
mov bx,0x8000
mov ch,0
mov cl,0x1
mov dl,[0x7c0e] ;dl contains hd
mov dh,0
clc
int 0x13
jc notok

mov ax,0x0201
mov bx,0x8000
mov ch,0
mov cl,0x2
mov dh,0
mov dl,[0x7c0e]
clc
int 0x13
jc notok

mov ax,0
clc
int 0x13
jc notok

mov ax,0x0201
mov bx,0x8000
mov ch,0
mov cl,0x3
mov dh,0
mov dl,[0x7c0e]
clc
int 0x13
jc notok


readagain2: ;final read

xor ax,ax
mov es,ax

sti
mov ax,0x0201
mov bx,0x7c00
mov ch,0
mov cl,0x1
mov dh,0
mov dl,[0x7c0e]
push dx
clc
int 0x13
pop dx
jc notok
nop
nop

jmp readok

notok:
sti
mov ax,0xb800
mov ds,ax
mov byte [0],'r';
mov byte [1],4;
mov byte [2],'a';
mov byte [3],4;
mov byte [4],'a';
mov byte [5],4;
mov byte [6],'h';
mov byte [7],4;

xor ax,ax
mov ds,ax
cmp byte [0x48d],0
jne notok2
nop
nop
nop
nop
nop
nop
nop
nop
jmp notok


notok2:
sti
xor ax,ax
mov ds,ax
cmp byte [0x48d],0
je hmm


mov ax,0xb800
mov ds,ax
mov byte [0],'F';
mov byte [1],4;
mov byte [2],'U';
mov byte [3],4;
mov byte [4],'C';
mov byte [5],4;
mov byte [6],'K';
mov byte [7],4;

jmp notok2

hmm:
sti
mov ax,0xb800
mov ds,ax
mov byte [0],'H';
mov byte [1],4;
mov byte [2],'M';
mov byte [3],4;
mov byte [4],'M';
mov byte [5],4;
mov byte [6],'M';
mov byte [7],4;
jmp hmm



bt_test:
jmp bt_test

readok:
mov ax,0xb800
mov ds,ax
mov byte [0],'B';
mov byte [1],6;
mov byte [2],'O';
mov byte [3],6;
mov byte [4],'O';
mov byte [5],6;
mov byte [6],'T';
mov byte [7],6;

;jmp readok

xor ax,ax
mov ds,ax

xor di,di
mov ss,ax
mov sp,0xfffe

;setup initial vars (excluding dl whith is set)
mov ax,[0x7022]
mov ss,ax

mov ax,[0x7024]
mov ds,ax

mov ax,[0x7026]
mov es,ax

mov ax,[0x7028]
mov fs,ax

mov ax,[0x702a]
mov gs,ax

mov eax,[0x700c] ;edx
mov al,dl
mov edx,eax

mov eax,[0x7000]
mov ebx,[0x7004]
mov ecx,[0x7008]
mov esi,[0x7010]
mov edi,[0x7014]
mov ebp,[0x7018]
mov esp,[0x701c]

mov eax,[0x7000]

lgdt [0x7030] ;restore gdt

push word [0x702c] ;restore eflags
popf

beforeboot:
nop
nop
nop


;jmp beforeboot
;int 19h

jmp 0x0000:0x7c00

;test^^^^
global bochswaitforsipiloop
bochswaitforsipiloop:
nop
cpuid
nop
jmp bochswaitforsipiloop

global vmxstartup_end
vmxstartup_end:

dd 0x00ce1337



