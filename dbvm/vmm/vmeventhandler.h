#ifndef VMEVENTHANDLER_H_
#define VMEVENTHANDLER_H_

#include "main.h"
#include "vmmhelper.h"

typedef struct
/* this struct is to keep track of what the guest sets in the comport */
{
  unsigned char Transmitter_Holding_Buffer; //baseport+0 write
  unsigned char Receiver_Buffer; //baseport+0 read
  unsigned char Devisor_Latch_Low; //baseport+0 read/write DLAB=1

  unsigned char Interrupt_Enable_Register; //baseport+1 read/write
  unsigned char Devisor_Latch_High; //baseport+1 read/write DLAB=1

  unsigned char Interrupt_Identification_Register; //baseport+2 read
  unsigned char FIFO_Control_Register; //baseport+2 write

  unsigned char Line_Control_Register; //baseport+3 read/write
  unsigned char Modem_Control_Register; //baseport+4 read/write

  unsigned char Line_Status_Register; //baseport+5 read
  unsigned char Modem_Status_Register; //baseport+6 read

  unsigned char Scratch_Register; //baseport+7 read/write
} FakeCOMport, *PFakeCOMport;
FakeCOMport fakecom1;


int DidHLT;

typedef struct
{
  union {
    ULONG Exit_Qualification;
    struct {
      ULONG size      : 3;  //0=1byte 1=2 byte, 3=4 byte.  (size+1 is bytesize)
      ULONG direction : 1;  //0=OUT 1=IN
      ULONG isstring  : 1;  //0=no string, 1=string
      ULONG hasrep    : 1;  //0=not rep, 1=rep
      ULONG opperand  : 1;  //0=DX, 1=immeadiate
      ULONG reserved  : 9;
      ULONG portnr    : 16; //port number
    };
  };
} __attribute__((__packed__)) IOExit_Qualification;


int handleVMEvent(pcpuinfo currentcpuinfo, VMRegisters *vmregisters);


ULONG getSegmentLimit(PGDT_ENTRY gdt, PGDT_ENTRY ldt, ULONG selector);
ULONG getSegmentBase(PGDT_ENTRY gdt, PGDT_ENTRY ldt, ULONG selector);
UINT64 getSegmentBaseEx(PGDT_ENTRY gdt, PGDT_ENTRY ldt, ULONG selector, int expandto80bit);
void setDescriptorAccessedFlag(PGDT_ENTRY gdt, PGDT_ENTRY ldt, ULONG selector);
ULONG getSegmentAccessRights(PGDT_ENTRY gdt, PGDT_ENTRY ldt, ULONG selector);
ULONG getSegmentAttrib(PGDT_ENTRY gdt, PGDT_ENTRY ldt, ULONG selector);

int setVM_CR0(pcpuinfo currentcpuinfo, UINT64 newcr0);
int setVM_CR3(pcpuinfo currentcpuinfo, VMRegisters *vmregisters, UINT64 newcr3);
int setVM_CR4(pcpuinfo currentcpuinfo, UINT64 newcr4);

int emulateExceptionInterrupt(pcpuinfo currentcpuinfo, VMRegisters *vmregisters, unsigned int cs, UINT64 rip, int haserrorcode, UINT64 errorcode, int isFault);

#endif
