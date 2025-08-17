//16/08/2025
#include "pico/stdio.h"
#include "pico/stdlib.h"

#include "tusb.h"
#include "boards.h"
#include "ice_flash.h"
#include "ice_fpga.h"

static inline void memdump(uint8_t const *buf, size_t sz, uint32_t addr)
{
    while (sz > 0) {
        printf("0x%08lX:", addr);
        for (size_t n = 0x20; sz > 0 && n > 0; sz--, buf++, n--, addr++) {
            printf(" %02X", *buf);
        }
        printf("\n");
    }
}

static inline int getchar_data() {
    int c;
    while((c=getchar_timeout_us(50000))==PICO_ERROR_TIMEOUT) {
        tud_task();
    }
    return c;
}

uint32_t read_uvarint(void) {
    uint32_t value = 0;
    int shift = 0;
    int c;

    while (1) {
        c = getchar_data();
        if (c == '\n') { // handle EOF or error
            return 0;
        }

        uint8_t byte = (uint8_t)c;

        // take the lower 7 bits, shift them into place
        value |= (uint32_t)(byte & 0x7F) << shift;

        if ((byte & 0x80) == 0) {
            break; // last byte
        }

        shift += 7;
    }

    return value;
}

void printf_int(int data){
    char buffer[32];
    sprintf(buffer,"%d",data);
    printf("%s",buffer);
}
int main(void) {
    
    // uint8_t data[ICE_FLASH_PAGE_SIZE]={'\0'};
    // memset(data,0xff,ICE_FLASH_PAGE_SIZE);

    // //Enable usb uart 0 output
    // stdio_init_all();

    // sleep_ms(2000);

    // int c;
    // char buffer[512]={'\0'};
    // int buffer_ptr=0;
    // while(1){
    //     while((c=getchar_timeout_us(10000)) == PICO_ERROR_TIMEOUT) {
    //         tud_task();
    //     }
    //     if(c=='\r' || c=='\n'){
    //         printf("%s",buffer);
    //         for(int i=0;i<512;i++) buffer[i]='\0';
    //         printf("\n");


    //         buffer_ptr=0;
    //     }else {
    //         if(buffer_ptr+1 >= 512) {
    //             printf("%s" ,buffer);
    //             for(int i=0;i<512;i++) buffer[i]='\0';
    //             buffer_ptr=0;
    //         }
    //         else
    //             buffer[buffer_ptr++]=c;
    //     }
    // }

    // while(1) {
    //     sleep_ms(2000);
    //     printf("hello\n");
    // }
    //take control of flash
    // ice_flash_init(FPGA_DATA.bus,ICE_FLASH_BAUDRATE);

    // uint32_t base_address=(uint32_t)0x00200000;
    // ice_flash_erase_sector(FPGA_DATA.bus,base_address);
    // uint8_t arr[] = {0xbb,0xbb,0xcc,0xdd,0xee};
    // memcpy(data,arr,sizeof(arr));
    // ice_flash_program_page(FPGA_DATA.bus,base_address,data);

    // // ice_flash_program_page(FPGA_DATA.bus,base_address,arr);

    // sleep_ms(1000);
    // uint8_t buffer[512];
    // ice_flash_read(FPGA_DATA.bus,base_address,buffer,sizeof(buffer));

    // printf("buffer contents\n");
    // memdump(buffer, sizeof(buffer),base_address);
    // return 0;


    stdio_init_all();

    uint32_t base_address = (uint32_t)0x00200000;

    ice_flash_init(FPGA_DATA.bus,ICE_FLASH_BAUDRATE); //i forgot this thing and spent half a day debugging :)


    int c=getchar_data();
    sleep_ms(2000);
    int size=0;

    if(c=='w'){
        printf("flash writer mode\n");
        ice_flash_erase_sector(FPGA_DATA.bus,base_address); //4kb erase (assuming)
        size = read_uvarint();


            printf("size is\n");
            printf_int(size);
            uint8_t page[ICE_FLASH_PAGE_SIZE];
            memset(page,0xff,ICE_FLASH_PAGE_SIZE);

            int page_count = (int)(size/ICE_FLASH_PAGE_SIZE);
            int remaining_page_bytes = size % ICE_FLASH_PAGE_SIZE;

            uint32_t offset=base_address;
            for(int i=0;i<page_count;i++) {
                for(int j=0;j<ICE_FLASH_PAGE_SIZE;j++) {
                    page[j]=getchar_data();
                }
                // printf("page ");
                // printf_int(i);
                // printf("page value\n");
                // printf("%.*s",ICE_FLASH_PAGE_SIZE,page);
                // printf("\n");

                ice_flash_program_page(FPGA_DATA.bus,offset,page);
                offset+=ICE_FLASH_PAGE_SIZE;
                // printf("page ");
                // printf_int(offset);
                // printf("\n");

                memset(page,0xff,ICE_FLASH_PAGE_SIZE);
            }

            
            for(int i=0;i<remaining_page_bytes;i++) page[i]=getchar_data();
            ice_flash_program_page(FPGA_DATA.bus,offset,page);
            offset+=ICE_FLASH_PAGE_SIZE;
            // printf("remaning page bytes\n");
            // printf("%.*s\n",ICE_FLASH_PAGE_SIZE,page);
            printf("done\n");
            printf("flashed till address ");
            printf_int(offset);
            printf("\n");

    }

    c=getchar_data();
    if(c=='r') {
        printf("reading\n");

        uint8_t page[ICE_FLASH_PAGE_SIZE];
        uint32_t offset=base_address;

        int page_count = (int)(size/ICE_FLASH_PAGE_SIZE);
        // int remaining_page_bytes = size % ICE_FLASH_PAGE_SIZE;

        for(int i=0;i<page_count;i++){
            printf("offset from read ");
            printf_int(offset);
            printf(" ");
            ice_flash_read(FPGA_DATA.bus,offset,page,ICE_FLASH_PAGE_SIZE);
            // printf("%.*s",ICE_FLASH_PAGE_SIZE,page);
            for(int i=0;i<ICE_FLASH_PAGE_SIZE;i++) putchar(page[i]);
                printf("half");
            offset+=ICE_FLASH_PAGE_SIZE;
                printf("offset1");
                printf_int(offset);
        }
        ice_flash_read(FPGA_DATA.bus,offset,page,ICE_FLASH_PAGE_SIZE);
        for(int i=0;i<ICE_FLASH_PAGE_SIZE;i++) putchar(page[i]);
        offset+=ICE_FLASH_PAGE_SIZE;
        printf("done reading at address ");
        printf_int(offset);
        printf("offset1");
                printf_int(offset);
        printf("\n");

        
    }

    // // ice_flash_erase_sector(FPGA_DATA.bus,0x200000); //4kb erase (assuming)
    // // sleep_ms(2000);
    // // uint8_t flash[ICE_FLASH_PAGE_SIZE];
    // // memset(flash,0x41,40);
    // // // for(int i=0;i<256;i++) flash[i]=0x41;

    // // ice_flash_program_page(FPGA_DATA.bus,0x200000,flash);
    // // // memset(flash,0x42,255);

    // // // ice_flash_program_page(FPGA_DATA.bus,0x200100,flash);


    // // sleep_ms(2000);
    // // // memset(flash,0x00,ICE_FLASH_PAGE_SIZE);
    // // int g=getchar_data();

    // uint8_t data[ICE_FLASH_PAGE_SIZE]={0};
    // ice_flash_read(FPGA_DATA.bus,0x200000,data,sizeof(data));
    
    // printf("data from first");
    // for(int i=0;i<sizeof(data);i++) putchar(data[i]);
    // memdump(data,256,base_address);
    // printf("\n");
    // // // memset(flash,0x00,ICE_FLASH_PAGE_SIZE);

    // // // ice_flash_read(FPGA_DATA.bus,0x200100,flash,ICE_FLASH_PAGE_SIZE);
    // // // printf("data from second");
    // // // for(int i=0;i<sizeof(flash);i++) putchar(flash[i]);
    // // printf("\n");
}   
