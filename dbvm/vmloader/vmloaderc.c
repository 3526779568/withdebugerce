/*
vmloaderc.c:  This is called by vmloader.asm, which has it's base at 0x30100
_vmloader_main is the entry in this c file

This is the high level part that will copy the vmm to the highest memorylocation
Then setup the pagetables to point to the vmm (identify pagemapping btw...)
enable paging, and jump to the vmm entry (which has it's base at virtual address 0x0)
*/
#include "common.h"

#ifndef VMMSIZE
  #define VMMSIZE 0
#endif

extern int reservedmem_listcount;
extern int pagedirptrbase;
extern void gotoVMM(void) __attribute__((stdcall));
extern int readsectorasm(void) __attribute__((stdcall));
extern void halt(void) __attribute__((stdcall));

unsigned int isAP=0;

unsigned short int VMMlocation;
unsigned short int LOGOlocation;

extern int a20state;

//disk
extern int readerror;
extern int sectorsread;

extern int bootdisk;
extern int SectorsPerTrack;
extern int NumberOfHeads;
extern int NumberOfCylinders;

extern unsigned int vmmPA;

int readsector(int sectornr, void *destination)
{
	struct
	{
		BYTE sector;
		BYTE head;
		BYTE cylinder;
		BYTE drive;
	} __attribute__((__packed__)) *readstruct=(void *)0x00070000;




  //configure parameters at 0x00070000
	readstruct->sector=(sectornr % (SectorsPerTrack-1));
	readstruct->head=(sectornr/(SectorsPerTrack-1)) % NumberOfHeads;
	readstruct->cylinder=(sectornr/(SectorsPerTrack-1))/NumberOfHeads;
	readstruct->drive=bootdisk;
	readstruct->sector++;

	//displayline("Read: disk=%2 cylinder=%d head=%d sector=%d...",readstruct->drive, readstruct->head, readstruct->cylinder, readstruct->sector );

	zeromemory((void *)0x00060000,512);


	if (readsectorasm()==1)
	{
		//sendstringf("Successfull read. Writing to %8\n\r",(ULONG)destination);
		//displayline("Success\n");
		copymem(destination,(void *)0x00060000,512);
		return 1;
	}
	else
	{
		//displayline("Failure\n");
		return 0;
	}
}

int _vmloader_main(void)
{
	PARD p;


	unsigned char bootsector[512];
	int i;
	unsigned long long maxAvailableAddress=0;
	unsigned long long tempbase,templength;
	int chosenregion=-1;
	nosendchar[getAPICID()]=0;



	sendstringf("\n\n--------------------------------\n\r");
	sendstringf("Welcome to Dark Byte\'s vmloader\n\r");
	sendstringf("--------------------------------\n\r");


	sendstringf("a=%8\n\r",readerror);
	sendstringf("b=%8\n\r",sectorsread);


	sendstringf("_vmloader_main got loaded at address %8\n\r",(unsigned int)_vmloader_main);
	sendstringf("reservedmem_listcount=%d (address of it = %8 ) \n\r",reservedmem_listcount,&reservedmem_listcount);

	sendstringf("Going to read the VMM into memory...\n\r");




	sendstringf("isAP value=%2  (address=%8)\n\r",isAP,(ULONG)&isAP);





	if (!isAP)
	{
		printstring("\311\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\273", 0,0,15, 1);
		printstring("\272                                                                             \272", 0,1,15, 1);
		printstring("\272                                                                             \272", 0,2,15, 1);
		printstring("\272                                                                             \272", 0,3,15, 1);
		printstring("\272                                                                             \272", 0,4,15, 1);
		printstring("\310\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\274", 0,5,15, 1);

		printstring("This tool originated at",40-11,2,10,1);
		printstring("www.cheatengine.org",40-8,3,12,1);

		currentdisplayline=7;

		displayline("a20state=%d (should be 1)\n",a20state);
		displayline("bootdrive=%2 (stored at %p)\n",bootdisk, &bootdisk);
		displayline("SectorsPerTrack=%d\n",SectorsPerTrack);
		displayline("NumberOfHeads=%d\n",NumberOfHeads);
		displayline("NumberOfCylinders=%d\n",NumberOfCylinders);

		displayline("&bootsector=%p\n", &bootsector);

		displayline("Testing diskread ability....");


  //  waitforkeypress();
 //   waitforkeypress();


		if (!readsector(0, bootsector))
		{
		  sendstringf("Error loading the bootsector.\n");
			displayline("Error loading the bootsector.\n");
			while (1) ;

			readsector(-1, bootsector);
			readsector(0, bootsector);
			readsector(1, bootsector);
			readsector(2, bootsector);


			halt();
		}
		else
		{
		  displayline("Successfully loaded the bootsector\n");

		  /*
		  for (i=0; i<512; i++)
		    displayline("%2 ", bootsector[i]);
*/
	  //  waitforkeypress();
	  //  waitforkeypress();
		}


		VMMlocation=*(unsigned short int *)&bootsector[0x8];
		LOGOlocation=*(unsigned short int *)&bootsector[0x10];
		sendstringf("VMM starts at sector %d\n\r",VMMlocation);
		sendstringf("LOGO starts at sector %d\n\r",LOGOlocation);

		displayline("VMM starts at sector %d\n",VMMlocation);


		isAP=1;
		p=(PARD)0x80000;
		for (i=0; i<reservedmem_listcount;i++)
		{
			tempbase=((unsigned long long)p[i].BaseAddrHigh << 32)+p[i].BaseAddrLow;
			templength=((unsigned long long)p[i].LengthHigh << 32)+p[i].LengthLow;

			sendstringf("i=%d : BaseAddress=%6, Length=%6, Type=%d ",i, tempbase, templength, p[i].Type);
			displayline("i=%d : BaseAddress=%6, Length=%6, Type=%d \n\r",i, tempbase, templength, p[i].Type);

			if (((tempbase+templength) < 0x100000000ULL ) && (templength>=0x800000) && (p[i].Type==1) && (tempbase+templength>maxAvailableAddress) )
			{
				maxAvailableAddress=tempbase+templength;
				chosenregion=i;

				sendstringf(" < 'new' potential region");

			}

			sendstring("\n\r");


		}


    //waitforkeypress();
    //waitforkeypress();

		if (chosenregion==-1)
		{
			displayline("Failure in picking a fitting region\n");
			halt();
		}



		/* adjust memory map */
		p[reservedmem_listcount].BaseAddrHigh=0;
		p[reservedmem_listcount].BaseAddrLow=0;
		p[reservedmem_listcount].LengthHigh=0;
		p[reservedmem_listcount].LengthLow=0;
		p[reservedmem_listcount].Type=255;  //mark as end of list (for vmm)


		if (maxAvailableAddress==0)
		{
			sendstringf("Not enough usable memory (at end)\n\r");
			displayline("Not enough usable memory (at end)\n\r");
		}
		else
		{
			unsigned int start; //unsigned int for 32-bit
			unsigned int gdt;
			unsigned int oldend;
			PPDE2MB_PAE PageDir;
			PPDPTE_PAE PageDirPtr;
			PPDPTE_PAE PageMapLevel4;


			sendstringf("Max address=%6  (region %d)\n\r",maxAvailableAddress, chosenregion);

			/* create a pagetable for the vmm and it's stack at this location */
			/* the vmm is loaded at address 0x60000 */
			start=(maxAvailableAddress-4*1024*1024);

			sendstringf("1:start=%8\n\r",start);
			displayline("1:start=%8\n\r",start);

			sendstringf("1.5:start mod 0x00400000=%8 \n\r",start % 0x00400000);
			displayline("1.5:start mod 0x00400000=%8 \n\r",start % 0x00400000);
			start-=start % 0x00400000;

			sendstringf("2:start=%8\n\r",start);
			displayline("2:start=%8\n\r",start);

			sendstringf("chosenregion=%d\n\r",chosenregion);
			displayline("chosenregion=%d\n\r",chosenregion);


			sendstringf("Adjusting memory map (done for physical memory access devices)\n\r");
			displayline("Adjusting memory map (done for physical memory access devices)\n\r");
			oldend=p[chosenregion].BaseAddrLow+p[chosenregion].LengthLow;
			p[chosenregion].LengthLow=start-p[chosenregion].BaseAddrLow;
			if (p[chosenregion+1].Type==2) //I hope so
			{
				oldend=p[chosenregion+1].BaseAddrLow+p[chosenregion+1].LengthLow;
				//adjust begin and length of this reserved region to encompass the lost memory
				p[chosenregion+1].BaseAddrLow=start;
				p[chosenregion+1].LengthLow=oldend-start;

				sendstringf("Adjusted reserved memory size as well\n\r");
				displayline("Adjusted reserved memory size as well\n\r");
			}
			else
			{
				//insert a new one
				for (i=reservedmem_listcount;i>chosenregion;i--)
					p[i]=p[i-1];


				p[chosenregion+1].BaseAddrHigh=0;
				p[chosenregion+1].BaseAddrLow=start;
				p[chosenregion+1].LengthHigh=0;
				p[chosenregion+1].LengthLow=oldend-start;
				p[chosenregion+1].Type=2;  //reserved

				reservedmem_listcount++;
				sendstringf("inserted new region\n\r");
				displayline("inserted new region\n\r");
			}

    //  waitforkeypress();
    //  waitforkeypress();

			sendstringf("newmap=\n\r");
			displayline("newmap=\n\r");
			for (i=0; i<reservedmem_listcount;i++)
			{
				tempbase=((unsigned long long)p[i].BaseAddrHigh << 32)+p[i].BaseAddrLow;
				templength=((unsigned long long)p[i].LengthHigh << 32)+p[i].LengthLow;
				sendstringf("i=%d : BaseAddress=%6, Length=%6, Type=%d \n\r",i, tempbase, templength, p[i].Type);
				displayline("i=%d : BaseAddress=%6, Length=%6, Type=%d \n\r",i, tempbase, templength, p[i].Type);
			}

			sendstringf("reservedmem_listcount=%d\n", reservedmem_listcount);
			displayline("reservedmem_listcount=%d\n", reservedmem_listcount);

		//	waitforkeypress();
		//	waitforkeypress();


			p[reservedmem_listcount].BaseAddrHigh=0;
			p[reservedmem_listcount].BaseAddrLow=0;
			p[reservedmem_listcount].LengthHigh=0;
			p[reservedmem_listcount].LengthLow=0;
			p[reservedmem_listcount].Type=255;  //mark as end of list (for vmm)

		//	*(int *)0x88000=reservedmem_listcount;

			sendstringf("Going to zero 0x00400000 bytes at %p\n", start);
			displayline("Going to zero 0x00400000 bytes at %p\n", start);
      //waitforkeypress();
      //waitforkeypress();

			zeromemory((void *)start, 0x00400000 /*VMMSIZE*/); //I wondered why this was crashing on a normal reboot. That is because the AP cpu's are in an infinite loop in this code. So,. first disable the AP cpu's before calling qucikboot

//		  waitforkeypress();
		  //waitforkeypress();

			/* read the vmm into the end of memory */
			displayline("Reading %d bytes from disk into %8 ...",VMMSIZE, (unsigned int)start);

			displayline("VMMlocation=%8\n",VMMlocation);
			displayline("start=%8\n",start);
			displayline("VMMSIZE=%8\n",VMMSIZE);


	    //waitforkeypress();
	    //waitforkeypress();

			int bytesread=0;
			while (bytesread<VMMSIZE)
			{
				if (readsector(VMMlocation+(bytesread / 512),(void*)((ULONG)start+bytesread)))
				{
					displayline("+");
		      //waitforkeypress();
		      //waitforkeypress();
					bytesread+=512;
				}
				else
				{
					displayline("Read error after %d bytes\n",bytesread);
					while (1)
					{
					  displayline("ERROR!\n");
					}

//					halt();
				}
			}
			displayline("\n");


      displayline("Read successful\n");

      //waitforkeypress();
      //waitforkeypress();



      /* place gdt */
      gdt=(start+VMMSIZE+4096) & 0xfffff000;
      sendstringf("gdtbase=%8\n\r",gdt);


      copymem((void *)gdt,(void *)0x50000,0x6f);

      /* setup pagedir / pages */
      pagedirptrbase=(start+VMMSIZE+2*4096) & 0xfffff000;


      sendstringf("pagedirptrbase=%8\n\r",pagedirptrbase);
      displayline("pagedirptrbase=%8\n\r",pagedirptrbase);

      PageMapLevel4=(PPDPTE_PAE)pagedirptrbase;
      zeromemory((void *)PageMapLevel4,4096);

      PageDirPtr=(PPDPTE_PAE)(pagedirptrbase+4096);
      zeromemory((void *)PageDirPtr,4096);

      PageDir=(PPDE2MB_PAE)(pagedirptrbase+4096+4096);
      zeromemory((void *)PageDir,4096);

      PageMapLevel4[0].P=1;
      PageMapLevel4[0].RW=1;
      PageMapLevel4[0].PFN=(ULONG)PageDirPtr >> 12;


			PageDirPtr[0].P=1;
      PageDirPtr[0].RW=1;
			PageDirPtr[0].PFN=(ULONG)PageDir >> 12;


      //(0x00000000 - 0x001fffff)
      PageDir[0].P=1;   //present
      PageDir[0].RW=1;  //writable
      PageDir[0].PS=1;  //2MB (PAE)
      PageDir[0].PFN=0; //0x00000000

			//(0x00200000 - 0x003fffff)
      PageDir[1].P=1;   //present
      PageDir[1].RW=1;  //writable
      PageDir[1].PS=1;  //2MB (PAE)
      PageDir[1].PFN=0x00200000 >> 13; //0x00000000

      //(0x00400000 - 0x005fffff)
      PageDir[2].P=1;   //present
      PageDir[2].RW=1;  //writable
      PageDir[2].PS=1;  //2MB
      PageDir[2].PFN=start >> 13; //0

      vmmPA=start;

			//(0x00600000 - 0x007fffff)
      PageDir[3].P=1;   //present
      PageDir[3].RW=1;  //writable
      PageDir[3].PS=1;  //2MB
      PageDir[3].PFN=(start+0x00200000) >> 13; //0


      //no pages...

      sendstringf("PageDirPtr[0].PFN=%8\n\r",PageDirPtr[0].PFN);


      int t,v;
      unsigned char *u;

      sendstringf("\n\r\n\r%8:\n\r",(ULONG)start);
      u=(unsigned char*)start;

      for (v=0; v<8; v++)
      {
        sendstringf("%8 : ",start+(16*v));

        for (t=0; t<16; t++,u++)
          sendstringf("%2 ",*u);


        sendstring("\n\r");
      }

      //init config variables
      UINT64 *s=(UINT64 *)start;

      s[2]=0; //no loadedOS
      s[3]=start; //physical address of the vmm start
      s[4]=0x00400000+VMMSIZE+2*4096;


      /* 0 to 4MB will be identity mapped */
      /* 4MB to 8MB will point to the vmm and it's stack */
      sendstringf("vmloader finished. Switching from 32-bit to 64-bit and entering VMM\n");
      displayline("vmloader finished. Switching from 32-bit to 64-bit and entering VMM\n");
     // displayline("Press any key to continue\n");
      //waitforkeypress();

      //whipe screen
      for (i=1; i<25; i++)
        displayline("\n");

      gotoVMM();
    }
  }
  else
  {
    sendstringf("This is a Application Processor\n\r");
    gotoVMM();
  }


	sendstringf("I managed to get to the end of the function. YEEEH!!!\n\r");


	return 0;
};
