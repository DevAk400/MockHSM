# MockHSM  
![Mock HSM Logo](assets/logo.svg)


## Overview
MockHSM emulates the Thales HSM Payshield 10000. It's designed for developers who need to test against an HSM. Many developers will not have access because HSMs are expensive pieces of equipment.  

MockHSM implements a set of commands that are integral to the modern payments system and involved in billions of transactions a day (eg: PIN block encryption). MockHSM focuses on modern AES encryption - DES is out of scope.

The code is well-structured and extensible, so other HSM commands can be easily added. We welcome contributions, and suggestions for other commands.


## Features of MockHSM
- A0 generate Key
- M0 encrypt a message
- M2 decrypt a message
- BA Encrypt a PIN block
- NG decrypt a PIN block
- JG transfer a PIN block under an LMK to a ZPK
- JE transfer a PIN block under a ZPK to an LMK
- B2 echo a message
- C6 generate random hex characters
- N0 generate a specified number of random bytes


## Setup
Clone into your chosen folder, and start the server:  
```rb
ruby starthsm.rb
```
You are now ready to send hsm commands to the server.  




## Usage

  All commands will follow this format:
  ```
  ./send2hsm.rb  <your command>
  ```


### M0 - Encrypt message  
M0 has several modes of encryption. Some of them require an IV (eg. CBC) while others don't (ECB). 



**ECB**
```
    export MODE="00"  # ECB
    export INPUT="2"  # text input
    export OUTPUT="1" # hex output
    export KEYTYPE="FFF"
    export KEY="S1009672AN00S0000EC9E765DB22164FC14AED94F78705188FA19EB7A56C46DCDBB2D48BE0966DF5A88172726D4B10273"
    export IV=""
    export LENGTH="0020"
    export MESSAGE="This is my encrypted message...."

    ./send2hsm.rb "M0${MODE}${INPUT}${OUTPUT}${KEYTYPE}${KEY}${IV}${LENGTH}${MESSAGE}"
```


**CBC**
```
    export MODE="01" # CBC
    export INPUT="2" 
    export OUTPUT="1"
    export KEYTYPE="FFF"
    export KEY="S1009672AN00S0000EC9E765DB22164FC14AED94F78705188FA19EB7A56C46DCDBB2D48BE0966DF5A88172726D4B10273"
    export IV="ADD8140EB113EFDC30D399DB13FAF397"
    export LENGTH="0020"
    export MESSAGE="This is my encrypted message...."

    ./send2hsm.rb "M0${MODE}${INPUT}${OUTPUT}${KEYTYPE}${KEY}${IV}${LENGTH}${MESSAGE}"
```

### M2 - Decrypt message  

**ECB**
```
    export MODE="00"  # ECB
    export INPUT="1"  # hex input
    export OUTPUT="2" # text output
    export KEYTYPE="FFF"
    export KEY="S1009672AN00S0000EC9E765DB22164FC14AED94F78705188FA19EB7A56C46DCDBB2D48BE0966DF5A88172726D4B10273"
    export IV=""
    export LENGTH="0040"
    export ENCRYPTED="AFAAE26089FE95D26F7F2E389540636CE38CDD3109495DDFF0E22E17B4B576FC"
    
    ./send2hsm.rb "M2${MODE}${INPUT}${OUTPUT}${KEYTYPE}${KEY}${IV}${LENGTH}${ENCRYPTED}"
```


**CBC**
```
    export MODE="01"  # CBC
    export INPUT="1"  
    export OUTPUT="2" 
    export KEYTYPE="FFF"
    export KEY="S1009672AN00S0000EC9E765DB22164FC14AED94F78705188FA19EB7A56C46DCDBB2D48BE0966DF5A88172726D4B10273"
    export IV="ADD8140EB113EFDC30D399DB13FAF397"
    export LENGTH="0040"
    export ENCRYPTED="32330C65826A54270C13C363BDDF9ACF0C5BA4AD638815C1902A447E8616A195"

    ./send2hsm.rb "M2${MODE}${INPUT}${OUTPUT}${KEYTYPE}${KEY}${IV}${LENGTH}${ENCRYPTED}"
```


### BA - Encrypt PIN block

```
    export PADPIN="1234FFFFFFFFFFFF"
    export PAN="1234567890123452"
    ./send2hsm.rb "BA${PADPIN}${PAN};"
```


### NG - Decrypt PIN block
```
    export PAN="1234567890123452"
    export ENCRYPTED="053171AC77DBDC883833939B2FA6985E"
    ./send2hsm.rb "NG${PAN};M${ENCRYPTED}"
```


### JG - Transfer from LMK to ZPK
A PIN block encrypted under the LMK may need to be transferred to another HSM. The destination HSM will have a different LMK so a Zone Pin Key must be used to encrypt the pin block during transit.  

```
    export ZPK="S1009672AN00S0000EC9E765DB22164FC14AED94F78705188FA19EB7A56C46DCDBB2D48BE0966DF5A88172726D4B10273"
    export MODE="48"
    export PAN="1234567890123452"
    export ENCRYPTED="053171AC77DBDC883833939B2FA6985E"
    ./send2hsm.rb "JG${ZPK}${MODE}${PAN};M${ENCRYPTED}"
```


### JE - Transfer from ZPK to LMK
```
    export ZPK="S1009672AN00S0000EC9E765DB22164FC14AED94F78705188FA19EB7A56C46DCDBB2D48BE0966DF5A88172726D4B10273"
    export PINBLOCK="7D807458092D288F072E31652D67F7DB"
    export MODE="48"
    export PAN="1234567890123452"
    ./send2hsm.rb "JE${ZPK}${PINBLOCK}${MODE}${PAN};"
```





## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.
