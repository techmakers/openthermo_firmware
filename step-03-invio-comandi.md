[Rotilio thermo - termostato open source](README.md) passo 3 di 7

## Inviare comandi al dispositivo e test software, hardware del termostato opensource

### Inviare comandi al dispositivo

Per poter impostare il modo di funzionamento del nostro dispositivo occorre prevedere la possibilità di inviargli le impostazioni di accensione o meno del riscaldamento e la temperatura desiderata.

Questo si ottiene creando due funzioni distinte, con lo scopo di modificare il valore delle variabili ```heaterOn``` e ```Ts```.

Iniziamo con scrivere le due apposite funzioni, che riceveranno in input il nuovo valore da impostare nelle rispettive variabili.

La funzione per impostare l'accensione del riscaldamento

```
int setHeaterMode(String _onoff){
    
    // cast from String to integer
    int onoff = _onoff.toInt();

    // input value check (returns an error code: 1 or 2) 
    if (onoff > 1) return 1 ; 
    if (onoff < 0) return 2 ;

    // set new value for heaterOn variable
    heaterOn = onoff ;

    // return 0 for OK 
    return 0 ;
}
```

e quella per impostare la temperatura desiderata

```
int setTempSetpoint(String _t){
    
    // cast from String to integer
    int t = _t.toInt() ;

    // input value check
    if (t < 18) return 1 ;
    if (t > 28) return 2 ;

    // set new value for Ts variable 
    Ts = t ;

    // returns 0 for OK
    return 0 ;
}
```

Il fatto di utilizzare una funzione per impostare il valore di una variabile ci consente di eseguire opportuni controlli di validità del dato in input prima di modificarne effettivamente il valore.

La funzione può restituire un valore intero, per convenzione, zero indica nessun errore, altri valori, diversi da zero indicano un errore.

Nel nostro caso, per entrambe le funzioni, un valore 1 restituito in uscita indica che il valore ricevuto in input è inferiore al minimo valore ammesso.
Un valore 2 indica invece che il valore ricevuto in input è superiore al massimo valore ammesso.

In questo modo, il dispositivo si autoprotegge, accettando 0 e 1 per la variabile heaterOn e valori compresi tra 18 e 28 °C per la variabile Ts.

Le due funzioni vanno aggiunte in fondo al nostro codice, ma perchè siano richiamabili dal cloud, occorre ancora un ultimo passaggio.

Dobbiamo "pubblicare” le funzioni, come abbiamo fatto per le variabili, utilizzando le API di Particle.io 

```
Particle.function("funcKey", funcName);
```

come indicato a questo indirizzo: [https://docs.particle.io/reference/firmware/photon/#particle-function-]()

Le righe di codice che pubblicano sul Cloud di Particle.io le nostre due funzioni vanno inserite nella funzione setup, ottenendo così quanto segue:


```
void setup(){

	Particle.variable("heateron",heaterOn);
	Particle.variable("temperature",T);
	Particle.variable("tempsetpoint",Ts);
	Particle.variable("relaisaorb",relaisAorB);

	Particle.function("setheater",setHeaterMode) ;
	Particle.function("settemp",setTempSetpoint) ;
	
	pinMode(D3,OUTPUT);
	pinMode(D4,OUTPUT);
	
	Wire.begin();
	
}
```

Trovate il codice completo del firmware a questo URL: [rotiliothermo_step03.ino](https://github.com/techmakers/rotiliothermo/blob/master/firmware/rotiliothermo_step03.ino).

Adesso possiamo inviare (Flash) il nuovo firmware al Photon e provare a richiamare le funzioni dal WEB.

#### Test di chiamata delle funzioni

Le nostre funzioni sono state pubblicate con i nomi: ```setheater``` e ```settemp```.

La chiamata via WEB deve avvenire con il metodo http POST. Il browser WEB permette, mediante inserimento di URL nella barra indirizzi, solo richieste con il metodo http GET.

Ecco come dovrebbe essere composta la POST.

```
POST /v1/devices/{DEVICE_ID}/{FUNCTION}
```

Per questo motivo, nel caso delle funzioni, occorre utilizzare uno strumento diverso dal browser.

Il più semplice e largamente disponibile è il comando ```curl```.

Potete scoprire se è disponibile nel vostro sistema aprendo una finestra di terminale, o prompt dei comandi, e digitare appunto ```curl --help```.

Se presente verrà listata una serie di opzioni disponibili per il comando curl.

Se non presente occorre installarlo, a seconda della piattaforma Linux, Mac o Windows del vostro PC è necessaria una differente, ma comunque semplice, procedura.


```
curl https://api.particle.io/v1/devices/420026001147343339383037/settemp \
     -d access_token=89d67f062abf6d45aa95f176642479d7caf5ca3c \
     -d "args=27"
```

eseguendo il comando otteniamo, se tutto corretto, una risposta come questa:

```
{"id":"420026001147343339383037","last_app":"","connected":true,"return_value":0}
```

Il valore ```return_value``` pari a 0 ci indica che il comando è stato recepito senza errori.

Se proviamo ad inviare una temperatura desiderata di 29 °C con il seguente comando:

```
curl https://api.particle.io/v1/devices/420026001147343339383037/settemp \
     -d access_token=89d67f062abf6d45aa95f176642479d7caf5ca3c \
     -d "args=29"
```

otteniamo una risposta come questa:

```
{"id":"420026001147343339383037","last_app":"","connected":true,"return_value":2}

```

Dove ```return_value``` è pari a 2, ovvero, valore superiore al massimo consentito di 28 °C.

## Testiamo il nostro termostato opensource

A questo punto del lavoro abbiamo inserito nel firmware tutti gli elementi necessari a controllare il riscaldamento mediante il nostro Rotilio Maker.

Il test è abbastanza semplice, partendo dal presupposto che:

- se la temperatura rilevata è inferiore a quella desiderata, il relè deve spostarsi in posizione A, altrimenti deve spostarsi in B

possiamo quindi, per verificare se il relè si sposta in posizione A, impostare una temperatura desiderata superiore alla temperatura rilevata, esempio:

- se la temperatura rilevata è di 25 gradi, potremo settare quella desiderata a 27 e capire se il relè si sposta da A a B.

L'attività di test si svolge su due fronti:

- software: inviamo comandi e leggiamo lo stato del dispositivo
- hardware: verifichiamo se il relè è nella posizione desiderata

Prima di procedere assicurarsi di non avere nessun collegamento elettrico sul morsetto del relè. Il test deve essere fatto "a vuoto".

### Sequenza di test software

Leggiamo la temperatura rilevata

```
curl https://api.particle.io/v1/devices/36001b001551353531343431/temperature?access_token=89d67f062abf6d45aa95f176642479d7caf5ca3c
```

Interpretiamo la risposta

```
{"cmd":"VarReturn","name":"temperature","result":24.3,"coreInfo":{"last_app":"","last_heard":"2017-09-22T14:02:37.021Z","connected":true,"last_handshake_at":"2017-09-22T12:04:59.090Z","deviceID":"36001b001551353531343431","product_id":6}}	
```
In questo caso leggiamo 24.3 °C

Impostiamo quindi una temperatura desiderata di 26 °C

```
curl https://api.particle.io/v1/devices/36001b001551353531343431/settemp \
     -d access_token=89d67f062abf6d45aa95f176642479d7caf5ca3c \
     -d "args=27"
```

Verifichiamo la risposta

```
{"id":"36001b001551353531343431","last_app":"","connected":true,"return_value":0}
```
In questo caso ```return_value``` è 0 quindi OK

Leggiamo se effettivamente Rotilio Maker ha recepito la temperatura desiserata

```
curl https://api.particle.io/v1/devices/36001b001551353531343431/tempsetpoint?access_token=89d67f062abf6d45aa95f176642479d7caf5ca3c
```

Verifichiamo la risposta

```
{"cmd":"VarReturn","name":"tempsetpoint","result":27,"coreInfo":{"last_app":"","last_heard":"2017-09-22T14:06:57.132Z","connected":true,"last_handshake_at":"2017-09-22T12:04:59.090Z","deviceID":"36001b001551353531343431","product_id":6}}
```

In questo caso ```result``` è 27, come ci aspettavamo.

Controlliamo se il relais è stato spostato in posizione A

```
curl https://api.particle.io/v1/devices/36001b001551353531343431/relaisAorB?access_token=89d67f062abf6d45aa95f176642479d7caf5ca3c
```

Verifichiamo la risposta

```
{"cmd":"VarReturn","name":"relaisAorB","result":0,"coreInfo":{"last_app":"","last_heard":"2017-09-22T14:08:47.371Z","connected":true,"last_handshake_at":"2017-09-22T12:04:59.090Z","deviceID":"36001b001551353531343431","product_id":6}}
```

In questo caso è ancora in posizione B, essendo ```result``` pari a 0.

E' normale, dato che il firmware opera ogni 30 secondi, quindi occorre attendere al massimo 30 secondi e riprovare la chiamata

```
curl https://api.particle.io/v1/devices/36001b001551353531343431/relaisAorB?access_token=89d67f062abf6d45aa95f176642479d7caf5ca3c
```

Verifichiamo nuovamente la risposta:

```
{"cmd":"VarReturn","name":"relaisAorB","result":1,"coreInfo":{"last_app":"","last_heard":"2017-09-22T14:11:17.308Z","connected":true,"last_handshake_at":"2017-09-22T12:04:59.090Z","deviceID":"36001b001551353531343431","product_id":6}}
```

Adesso ```result``` è pari a 1, quindi il relè è stato spostato in posizione A.

Dovremmo aver sentito anche il "click" del relè che cambia posizione.

### Test hardware

Il test hardware consiste nel verificare che le posizioni del relè corrispondano ai relativi contatti sul morsetto del relè.

La figura seguente illustra la posizione dei contatti e relativa chiusura.

![Rotilio Maker Explained Relais](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/RotilioThermoPictures.002.png)

Se usiamo un tester per verificare la continuità tra il "Common" e A, dovremo trovare continuità quando il relè è in posizione A e viceversa.

La continuità si misura sempre tra "Common" e A o tra "Common" e B, mai tra A e B.

## Collegamento del sistema di riscaldamento

Come detto inizialmente, il relè di Rotilio Maker dovrà essere collegato ai due fili che normalmente vanno dalla caldaia al termostato.

Le due figure seguenti illustrano i possibili collegamenti, che dovranno essere applicati al proprio caso.

Se la caldaia si aspetta il contatto chiuso per avviarsi, dovremo utilizzare il modo A, altrimenti il modo B.

![Heating system connection - Mode A](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/RotilioThermoPictures.003.png)

![Heating system connection - Mode B](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/RotilioThermoPictures.004.png)

## Cosa abbiamo imparato

Le nozioni fin qui acquisite appartengono al campo del software, dell'hardware e delle comunicazioni (cloud).

Per la parte software abbiamo imparato a scrivere un piccolo programma che, dato un determinato input, prende delle decisioni e fornisce un output.

Abbastanza tradizionale.

Il tutto però diventa interessante perchè gli input provengono da internet e dall'ambiente circonstante, dalle cose, ecco l'Internet delle Cose.

Abbiamo imparato ad azionare qualcosa, che è il nostro output, ovvero la posizione del relè e conseguentemente il funzionamento della caldaia.

[< Il firmware](step-02-firmware.md) | [Lettura temperatura >](step-04-lettura-temperatura.md)
