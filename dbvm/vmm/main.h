#ifndef MAIN_H_
#define MAIN_H_

#include "common.h"
#include "vmmhelper.h"


void startvmx(pcpuinfo currentcpuinfo);
void CheckCRCValues(void);

extern void vmcall_amd(void);
extern void vmcall_intel(void);

extern void *vmcall_instr; //holds a pointer to either vmcall_amd or vmcall_intel
extern int vmcalltest_asm(void);
extern int vmcall_setintredirects(void);

extern void _pause(void);
extern UINT64 _vmread(ULONG index);
extern void _vmwrite(ULONG index,UINT64 value);
extern int _vmclear(unsigned long long address);
extern int _vmptrld(unsigned long long address);
extern int _vmxon(unsigned long long address);
extern int _vmlaunch(void);
extern void _vmresume(void);
extern void _vmxoff(void);
extern void cLIDT(void *idtloader);
extern unsigned long long readMSR(ULONG msr);
extern void writeMSR(ULONG msr, UINT64 newvalue);
extern void _xsetbv(ULONG xcr, UINT64 value);
extern int stopautomation(void);
extern int hascpuid(void);
extern UINT64 getCR0(void);
extern UINT64 getCR2(void);
extern UINT64 getCR3(void);
extern UINT64 getCR4(void);
extern UINT64 getDR0(void);
extern UINT64 setDR0(UINT64 newdr0);
extern UINT64 getDR1(void);
extern UINT64 getDR2(void);
extern UINT64 getDR3(void);
extern UINT64 getDR6(void);
extern UINT64 setDR6(UINT64 newdr6);
extern UINT64 getDR7(void);
extern UINT64 setDR7(UINT64 newdr7);
extern void setIDT(UINT64 base, WORD size);
extern void setGDT(UINT64 base, WORD size);
extern UINT64 getIDTbase(void);
extern UINT64 getGDTbase(void);
extern WORD getIDTsize(void);
extern WORD getGDTsize(void);

//minor mistake fix and I hate renaming the function
#define getGDTlimit getGDTsize

extern UINT64 getRFLAGS(void);
extern void setRFLAGS(UINT64 rflags);
extern void loadTaskRegister(ULONG selector);
extern WORD getTaskRegister(void);
extern ULONG setCR0(UINT64 newcr0);
extern ULONG setCR2(UINT64 newcr2);
extern ULONG setCR3(UINT64 newcr3);
extern ULONG setCR4(UINT64 newcr4);
extern void _invlpg(UINT64 address);
extern UINT64 _rdtsc(void);
extern void quickboot(void);
extern void infloop(void);

void *idttable32;
void *jumptable;
extern void virtual8086_start(void);
extern int realmodetest;
extern int moveto32bitstart;
extern int virtual8086entry32bit;
extern int inthandler_32;
extern int real16;
extern int realmode;
extern int movetoreal;
extern int movetoreal_end;
extern int bochswaitforsipiloop;
extern UINT64 loadedOS;
PTSS mainTSS;

int vmxloop(pcpuinfo currentcpuinfo, UINT64 *eaxbase);
int vmxloop_amd(pcpuinfo currentcpuinfo, UINT64 vmcb_pa, UINT64 *eaxbase);

extern int vmxstartup_end;

extern unsigned long long IA32_APIC_BASE;
extern unsigned long long APIC_ID;
extern unsigned long long APIC_SVR;

extern int cpu_stepping;
extern int cpu_model;
extern int cpu_familyID;
extern int cpu_type;
extern int cpu_ext_modelID;
extern int cpu_ext_familyID;

extern int testcode(int i,int i2, int i3, int i4);

extern void changetask(void);
extern void tasktest(void);
extern void int3bptest(void);


volatile void       *RealmodeRing0Stack;
volatile PTSS       ownTSS;
volatile PTSS       VirtualMachineTSS_V8086;
unsigned char *ffpage;
PPDE_PAE   ffpagedir;
PPTE_PAE   ffpagetable;
int        memorycloak;

volatile void       *GDT_IDT_BASE; //gdt=0 idt=0x800

void menu(void);

//filled in by vmm.map parser
ULONG      Password1;
ULONG      Password2;
ULONG      dbvmversion;

//crc checksums
unsigned int originalIDTcrc;
unsigned int originalVMMcrc;


int isAMD;
int AMD_hasDecodeAssists;
int AMD_hasNRIPS;


#define vmclear _vmclear
#define vmptrld _vmptrld
#define vmxon _vmxon
#define vmlaunch _vmlaunch
#define vmresume _vmxresume
#define vmxoff _vmxoff
#define vmread _vmread
#define vmwrite _vmwrite


#endif /*MAIN_H_*/
