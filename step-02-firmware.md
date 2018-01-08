[Rotilio thermo - termostato open source](README.md) passo 2 di 7

## Il firmware, come caricarlo e test delle variabili

Il nostro obiettivo è quello di regolare la temperatura di casa o ufficio con impostazioni inviate da remoto.

La regolazione nel normale cronotermostato avviene misurando la temperatura ad un prestabilito intervallo di tempo, solitamente trenta secondi, o un minuto.
Se la temperatura è inferiore a quella richiesta, allora azioniamo la caldaia, altrimenti no.

Il cronotermostato esegue questo ciclo all'infinito, occorre però precisare che l'azionamento della caldaia viene eseguito dal cronotermostato solo se l'impostazione principale è: riscaldamento acceso.

Se vogliamo riprodurre questo funzionamento abbiamo bisogno di:

- un sensore di temperatura
- un relè (posizione A: caldaia abilitata, posizione B: caldaia disabilitata)
- una CPU

Iniziamo a scrivere un firmware che permetta al dispositivo Rotilio Maker di interagire con l'ambiente circostante misurando la temperatura e accendendo o meno la caldaia. Completato il firmware scriveremo una APP Mobile per poter interagire con i dispositivi.

### Il firmware

Il firmware che gira nella CPU di Rotilio Maker esegue due funzioni: ```setup``` e ```loop```.
La prima viene eseguita solo una volta, all'avviamento della CPU (quando Rotilio Maker viene alimentato), la seconda gira in un ciclo infinito (loop).

Per ogni esecuzione di ```loop``` dovremo:

1. leggere la temperatura interrogando l'apposito sensore
2. se la temperatura è inferiore a quella impostata ed è richiesto il riscaldamento, azionare il relè portandolo in posizione A, altrimenti azionare il relè in posizione B.
3. attendere 30 secondi

Vediamo un esempio di pseudo-codice Wiring(R) compatibile Arduino(R) che possa eseguire quanto sopra (scriviamo il codice sempre in inglese).

```
bool    heaterOn    = true  ;    // running mode
double  T           = 0.0   ;    // temperature from sensor °C
double  Ts          = 18.0  ;    // temperature setup °C
int     period      = 30000 ;    // milliseconds between each loop
int     relaisAorB  = 0     ;    // relais position: A=1, B=0, default B

void loop(){
	
	T = readTemperatureFromSensor() ;  // acquire actual temperature
	
	if (heaterOn && T < Ts) {
		relaisAorB = 1 ;       // actual temperature lower than desired, enable heating system
	} else {
		relaisAorB = 0 ;       // actual temperature ok, disable heating system
	}
	
	if (relaisAorB == 1) {
		relaisSet();           // switch relais to position A
	} else {
		relaisReset();         // switch ralais to position B
	}
	
	delay(period);            // wait for the next cycle
	
}
```

La funzione ```readTemperatureSensor``` interroga il sensore di temperatura e restituisce la temperatura letta, che verrà memorizzata nella variabile T.

La funzione ```relaisSet``` imposta il relè in posizione A.

La funzione ```relaisReset``` imposta il relè in posizione B.

La funzione ```delay``` attende il numero di secondi (in questo caso 30) ricevuti in input prima di proseguire nell'esecuzione.

La funzione ```loop``` viene eseguita dalla CPU all'infinito.

Le funzioni ```delay``` e ```loop``` sono predefinite, mentre le altre tre ```readTemperatureFromSensor```, ```relaisSet``` e ```relaisReset``` devono essere scritte appositamente, in funzione delle componenti e dei cablaggi eseguiti tra loro.

Alla pagina GitHub: [https://github.com/techmakers/rotilio.cc/tree/master/RotilioMaker]() si trovano tutte le info necessarie per capire come scrivere le suddette funzioni.

#### Partiamo dal relè

Il classico relè è un interruttore comandato elettricamente. Questo significa che per cambiare la sua posizione da A a B occorre inviargli un segnale elettrico. Nel caso di Rotilio Maker, il relè è connesso ai PIN del Photon D4 e D3. Il PIN D4 è connesso al piedino di ```set``` mentre il PIN D3 è connesso al piedino ```reset``` del relè.

Questo significa che per portare il relè in posizione A dobbiamo "alzare" il piedino D4. Per la posizione B dobbiamo invece "alzare" il piedino D3.

Una importante precisazione da fare relativamente al relè di Rotilio Maker è che si tratta di un relè "bistabile".
La sua particolarità è quella di mantenere l'ultima posizione impostata senza la necessità di tensione costante applicata ai piedini di ```set``` e ```reset```.
Questo ci permette, ad esempio, di spegnere la CPU e mantenere l'impostazione del relè nella posizione desiderata. Non dobbiamo dimenticarci di questo dettaglio, vedremo perchè in seguito.

La funzione ```relaisSet```, che porta il relè in posizione A dovrà quindi:

1. alzare il piedino D4 del Photon
2. attendere il tempo necessario perchè il relè si sposti sulla posizione ```set```
3. abbassare il piedino D4 del Photon

```
void relaisSet(){
    digitalWrite(D7,HIGH);    // signal on Photon led that relais is SET (Position A)
	digitalWrite(D4,HIGH);    // set PIN D4 high
	delay(100);				  // waits for 100 milliseconds
	digitalWrite(D4,LOW);     // set PIN D4 low
}
```

Similmente la funzione ```relaisReset```, che porta il relè in posizione B dovrà:

1. alzare il piedino D3 del Photon
2. attendere il tempo necessario perchè il relè si sposti sulla posizione ```reset```
3. abbassare il piedino D3 del Photon

```
void relaisReset(){
    digitalWrite(D7,LOW);     // signal on Photon led that relais is RESET (Position B)
	digitalWrite(D3,HIGH);    // set PIN D3 high
	delay(100);               // waits for 100 milliseconds
	digitalWrite(D3,LOW);     // set PIN D3 low
}
```

Perchè il tutto funzioni correttamente occorre impostare, in fase di avviamento della CPU, le modalità di funzionamento dei PIN del Photon. Questo in Wiring(R) deve essere eseguito nella funzione predefinita ```setup```.
I pin D3 e D4 devono essere impostati in modo che fungano come ```output```, visto che dovranno comandare il relè.

```
void setup(){
	pinMode(D3,OUTPUT);
	pinMode(D4,OUTPUT);
}
```

#### Passiamo al sensore di temperatura

In questo caso il sensore di temperatura è collegato ai PIN D0 e D1 del Photon, configurati in modalità I2C. Questa modalità permette di connettere più sensori sugli stessi PIN, aumentando così le possibilità di espansione del sistema.

Il sensore utilizzato su Rotilio Maker è un Si7020, prodotto da Silicon Labs, di cui possiamo reperire il data-sheet qui: [https://www.silabs.com/documents/public/data-sheets/Si7020-A20.pdf]()

L'interrogazione di un dispositivo I2C si svolge nei seguenti passaggi:

1. Inizio la trasmissione su bus I2C all'indirizzo desiderato (ogni dispositivo ha un suo indirizzo impostato in fabbrica)
2. Invio il comando da eseguire al dispositivo
3. Termino la trasmissione e attendo che il dispositivo sia pronto a rispondere
4. Leggo la risposta dal dispositivo, di solito uno o più bytes vengono letti

La risposta dal dispositivo solitamente ha bisogno di ulteriori passaggi per essere utilizzata:

1. compongo i byte ricevuti dal dispositivo in un valore intero
2. converto il valore intero nella scala desiderata, in questo caso gradi centigradi

La parte di comunicazione con il bus I2C è pronta all'uso nella libreria "Wire" che andremo ad includere nel nostro codice.

Scriviamo quindi una funzione "generica" per dialogare con i nostri sensori I2C, potrà tornarci utile in altri casi.

La seguente funzione ```readRawDataFromI2C``` riceve in input due informazioni:

- l'indirizzo del dispositivo I2C
- il comando da inviare al dispositivo

Restituirà in output un valore intero, che dovrà poi essere convertito nel valore desiderato.

```
int readRawDataFromI2C(int address,int command){

	// send read command to sensor over I2C bus
	Wire.beginTransmission(address);
	Wire.write(command);
	Wire.endTransmission();	
	
	// wait some time to let the sensor sense
	delay(20);
	
	// read three bytes from sensor
	Wire.requestFrom(address, 3);
	
	// compose a 16 bit value from 2 (msb and lsb) received bytes
	unsigned char msb = Wire.read();
	unsigned char lsb = Wire.read();
	unsigned char chk = Wire.read(); // checksum, not used
	int data = (((int) msb<<8) + (int) lsb);
	
	return data ;
}
```
Utilizziamo adesso la funzione ```readRawDataFromI2C``` per leggere nello specifico la temperatura dal nostro sensore. Le costanti di conversione, l'indirizzo I2C e il comando sono tratti dal data-sheet del sensore.

```
#define Si7020_ADDRESS              0x40
#define TEMPERATURE_READ_COMMAND    0xF3

double readTemperatureFromSensor(void){

	// read raw data from temperature sensor Si7020
	int data = readRawDataFromI2C(Si7020_ADDRESS, TEMPERATURE_READ_COMMAND);
	
	// convert raw data in celsius degrees
    double celsiusdegree = 175.72 * data / 65536 - 46.85;
    
    // round to first decimal
    double roundedcelsiusdegree = round(celsiusdegree*10)/10 ;
    
    return roundedcelsiusdegree ;
}
```
Non dimentichiamoci che la libreria "Wire" deve essere inizializzata all'avviamento della CPU, quindi modifichiamo la funzione ```setup``` come segue:

```
void setup(){
	pinMode(D3,OUTPUT);
	pinMode(D4,OUTPUT);
	Wire.begin();
}
```

A questo punto il firmware potrebbe essere pronto, se volete potete ottenere il codice completo di quanto fatto fino adesso, cliccando qui: [rotiliothermo_step01.ino](https://github.com/techmakers/rotiliothermo/blob/master/firmware/rotiliothermo_step01.ino).

Prima di procedere con il caricamento di questo sorgente sul Photon di Rotilio Maker, dobbiamo però risolvere un problema, anzi due: 

- non possiamo variare la temperatura impostata su un valore diverso dai 21 °C
- non possiamo mettere il riscaldamento in modalità "spento", a meno di non modificare le prime righe con valori di default per ```heaterOn``` e ```Ts```.

Inoltre non sappiamo se il nostro termostato ha inviato alla caldaia il comando di avviamento o meno.

Ma qui ci viene incontro Particle.io con le API di comunicazione con il Photon attraverso il cloud.

Le API di Particle.io, tra le altre cose, permettono di accedere a dati presenti nel dispositivo (variabili) e di inviare comandi al dispositivo (funzioni).

Potremo rendere leggibili dal Web le variabili ```T```, ```Ts```, ```heaterOn```, ```relaisAorB``` e chiamare delle funzioni che impostano ```heaterOn``` e ```Ts```.

### Come rendere leggibile una variabile.

Le variabili su pubblicano verso il WEB con la funzione ```Particle.variable("<nome_per_il_web>",variabile)```.

Tutte le informazioni relativamente alla pubblicazione di variabili nel Cloud sono disponibili sul sito Particle.io nella sezione documentazione: [https://docs.particle.io/reference/firmware/photon/#particle-variable-]()

Ecco un esempio applicato al nostro firmware.

```
Particle.variable("heateron",heaterOn);
```
Questa riga di codice va aggiunta nella funzione ```setup```, ottenendo quindi quanto segue:

```
void setup(){

	Particle.variable("heateron",heaterOn);
	
	pinMode(D3,OUTPUT);
	pinMode(D4,OUTPUT);
	Wire.begin();
}
```

Possiamo ripetere la cosa per le altre variabili, ottenendo quindi la funzione ```setup``` come segue:

```
void setup(){

	Particle.variable("heateron",heaterOn);
	Particle.variable("temperature",T);
	Particle.variable("tempsetpoint",Ts);
	Particle.variable("relaisaorb",relaisAorB);
	
	pinMode(D3,OUTPUT);
	pinMode(D4,OUTPUT);
	Wire.begin();
}
```

Non dimentichiamoci che:

- i nomi delle variabili Cloud possono essere lunghi al massimo 12 caratteri
- possiamo registrare al massimo 20 variabili Cloud

Da questo momento, caricando il firmware sul Photon con questa ultima versione della funzione ```setup``` sarà possibile leggere dal WEB le quattro variabili.

Vediamo un esempio:

```
https://api.particle.io/v1/devices/420026001147343339383037/heateron?access_token=89d67f062abf6d45aa95f176642479d7caf5ca3c
```

Attenzione, se provate ad aprire questo indirizzo senza prima aver caricato il firmware sul Photon, otterrete un messaggio di risposta come questo: ```{"ok":false,"error":"Unknown Variable: false"}```.

L'indirizzo appena menzionato è una composizione delle seguenti parti:

- url del cloud di Particle.io: ```https://api.particle.io```
- versione delle API: ```v1```
- funzione di accesso ai dispositivi: ```devices```
- id del dispositivo: ```420026001147343339383037 ```
- nome della variabile web: ```heateron```
- access_token, ovvero, la parola d'ordine, o password che dir si voglia, senza la quale non si può accedere al dispositivo: ```89d67f062abf6d45aa95f176642479d7caf5ca3c``` (quindi tenetela per voi)

### Caricare il firmware sul vostro Rotilio Maker

Si, è giunto il momento di provare davvero a comunicare con il vostro Rotilio Maker e i suoi sensori, questo grazie al firmware che caricheremo sul Photon grazie al cloud di Particle.io.

L'operazione la prima volta richiede un po' di passaggi, ma successivamente si rivelerà un lavoro di routine molto veloce e semplice.

Scomponiamo l'attività nei seguenti passaggi:

1. connessione di Rotilio Maker alla rete WiFi
2. accesso al cloud di Particle.io
3. Caricamento del firmware nel cloud di Particle.io
4. Invio del firmware al Rotilio Maker

#### Connessione di Rotilio Maker alla rete WiFi

Questa attività è più semplice se eseguita attraverso l'apposita APP Mobile fornita gratuitamente da Particle.io, potete scegliere tra queste piattaforme:

- [Android](https://play.google.com/store/apps/details?id=io.particle.android.app)
- [iOS](https://itunes.apple.com/us/app/particle-build-photon-electron/id991459054?ls=1&mt=8)
- [Windows](https://www.microsoft.com/en-us/store/p/particle/9nblggh4p55n)


Riassumiamo di seguito i passaggi, per poi rimandarvi alla apposita pagina di supporto di Particle.io.

1. Alimentare il Rotilio Maker (potete usare un cavetto USB collegato al vostro computer e al Photon del Rotilio Maker)
2. Se il LED del Photon esegue una serie di lampeggi per poi diventare azzurro evanescente, allora vuol dire che il collegamento alla WiFi era già stato eseguito, altrimenti dovrebbe lampeggiare di un colore blu scuro, in attesa di ricevere le credenziali della WiFi.
3. Mediante l'App Mobile di Particle.io, seguendo i passaggi indicati a questo indirizzo [https://docs.particle.io/guide/getting-started/start/photon/#step-1-power-on-your-device](), inserite le credenziali e verificate che il Photon si connetta alla vostra rete WiFi direttamente.

Se doveste incontrare delle difficoltà in questa fase, una risorsa utile è la pagina delle FAQ di Particle.io: [https://docs.particle.io/faq/particle-devices/led-troubleshooting/photon/]()

IMPORTANTE: Durante la fase di setup delle credenziali WiFi avviene anche la registrazione sul cloud di Particle.io. Le credenziali tenetele sotto mano, perchè servono anche al passaggio successivo, in modo da entrare sul cloud con le stesse utilizzate per attivare il Photon, e trovarlo quindi nella lista dei dispositivi associati all'account.

### Accesso al cloud di Particle.io

Come detto il cloud di Particle.io fornisce una serie di servizi tra cui:

- layer di comunicazione (e relative API) con i dispositivi

ma anche:

- ambiente di sviluppo integrato (IDE) [https://build.particle.io]()
- console di gestione dei dispositivi [https://console.particle.io]()
- documentazione delle API (cloud e firmware) [https://docs.particle.io]()

Al momento ci interessa l'ambiente di sviluppo integrato, quindi apriamo il relativo link e inseriamo, se è la prima volta che lo facciamo, le credenziali di accesso, le stesse utilizzate per attivare il Photon di Rotilio Maker.

Ecco cosa dovreste vedere cliccando qui con il vostro browser: [https://build.particle.io]()

![Particle.IO IDE Login](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/build_particle_io_login.png)

Appena inserite le proprie credenziali si presenta la schermata principale di Particle.io

![Particle.IO Main screen](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/particle_io_main.png)

Per accedere quindi all'IDE cliccate in alto a DX alla voce IDE appunto, verrete indirizzati ad una pagina come la seguente.

![Particle.IO IDE screen](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/particle_io_ide.png)

La schermata è divisa in due parti principali, a sinistra abbiamo la toolbar con le icone. Ogni click su un icona predispone la colonna subito a destra della toolbar con i contenuti e le azioni contestualizzate.
Nella parte di destra troviamo sempre l'editor del codice che potremo inviare al Photon.

Per poter caricare il firwmare sul Photon del Rotilio Maker dobbiamo:

1. copiare il firmware negli appunti, prelevandolo da questo indirizzo: [rotiliothermo_step02.ino](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/firmware/rotiliothermo_step02.ino)
2. selezionare il dispositivo target (quello a cui invieremo il firmware)
3. incollare il contenuto degli appunti nella parte destra della schermata
4. dare un nome al firmware, es: rotiliothermo_step02
5. salvare e compilare il firmware (in questa fase il codice viene caricato sul cloud)
6. inviare il firmware compilato al Photon (che deve essere connesso ad Internet perchè il trasferimento avviene tra il cloud e il Photon)

#### Copiare il firmware negli appunti

Potete prelevare i singoli pezzi di codice da questo tutorial e incollarli nella parte destra della schermata, oppure potete andare a questo indirizzo su GitHub: [rotiliothermo_step02.ino](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/firmware/rotiliothermo_step02.ino) come da schermata seguente, selezionare tutto e incollarlo negli appunti.

![GitHub code screen](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/github_rotiliothermo_code.png)

#### Selezionare il dispositivo target

Tornate nella schermata dell'IDE di Particle e cliccate sull'icona indicata con "1.a" e poi selezionate il dispositivo cliccando sulla relativa stellina come indicato con "1.b", infine cliccare sull'icona per tornare alla gestione applicazioni come indicato con "1.c".

![Particle.io IDE select device example](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/particle_io_ide_device_selection.png)

#### Incollare il contenuto degli appunti

Il codice del firmware va incollato nella parte destra dello schermo come nell'esempio seguente.

![Particle.IO IDE screen with code](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/particle_io_ide_with_code.png)

Prima di incollare abbiate cura di pulire la parte di destra del codice in modo che sia completamente sgombra e pronta per accogliere il codice che avete copiato negli appunti al punto 1.

#### Dare un nome al firmware

Digitare il nome dell'applicazione come indicato in figura seguente.

![Particle.IO IDE screen application name](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/particle_io_ide_application_name.png)

#### Salvare e compilare il firmware

Cliccare sull'icona di salvataggio (Save), poi su quella di compilazione (Verify) e se non vengono riportati errori procedere con l'invio del firmware al dispositivo (Flash), come nelle figure seguenti.

Save

![Particle.IO IDE screen application save](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/particle_io_ide_save.png)

Verify

![Particle.IO IDE screen application verify](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/particle_io_ide_verify.png)

Flash

![Particle.IO IDE screen application flash](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/particle_io_ide_flash.png)

In questa fase dovreste veder lampeggiare color magenta il LED del Photon, attendete fino quando il processo non si conclude, con la sequenza di colore verde lampegginte, azzurro lampeggiante, azzurro evanescente.

Ogni volta che andremo a modificare il firmware, sarà necessario ripetere l'ultimo punto (Flash) per inviare l'aggiornamento al nostro Photon.

### Test delle variabili

Appena ricevuto l'aggiornamento di firmware il Photon si riavvia e inizia ad eseguire il nuovo codice.

Prima di procedere con le altre attività la cosa migliore è verificare che le variabili siano realmente leggibili.

Come detto, la cosa è facilmente attuabile utilizzando un browser WEB inserendo nella barra degli indirizzi la stringa che corrisponde all'url del dispositivo e della variabile da testare.

Per comporre questa stringa ci occorrono tre informazioni specifiche:

- la nostra access_token
- il device ID
- il nome della variabile

#### Reperire l'access_token

L'access_token si può ottenere attraverso l'IDE di particle, cliccando sull'icona "Settings" nella schermata in basso a sinistra.

Si aprirà un pannello che mostra alcuni pulsanti e una casella di testo contenente l'access_token.

![Particle.IO IDE screen access_token](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/particle_io_ide_settings_access_token.png)

Copiate e incollate l'access_token in un editor di testo.

#### Reperire il device ID

Il device ID è una stringa di caratteri esadecimali che contraddistingue ogni device Particle.io in maniera univoca in tutto il mondo.
Ogni device viene serializzato con una stringa univoca in fabbrica, questa stringa non si può cambiare.
La coppia "deviceID & access_token" sono l'equivalente di nome utente e password. Tenerli al sicuro garantisce che nessun altro possa interagire con il nostro device.

Anche il device ID è reperibile attraverso l'IDE di Particle.io, come in figura, cliccare sull'icona dei device (il mirino), si aprirà un pannello con l'elenco dei device, cliccare quindi sul freccino a destra di ogni device per aprire i dettagli del device desiderato.

![Particle.IO IDE screen access_token](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/particle_io_ide_device_id.png)

Se avete diversi device, utilizzate il tasto SIGNAL per verificare che il device selezionato sia quello giusto. Se è quello giusto, al click del tasto SIGNAL il LED del device inizierà a lampeggiare con i colori di un arcobaleno.

Copiate e incollate il device ID in un editor di testo.

#### Eseguiamo il test di lettura delle variabili

Adesso che abbiamo tutti gli elementi possiamo comporre, nel nostro editor di testo preferito, l'url che poi copieremo e incolleremo nella barra degli indirizzi del browser.

Se vogliamo leggere la temperatura rilevata dal sensore di Rotilio Maker, dovremo comporre un URL come il seguente:

```
https://api.particle.io/v1/devices/420026001147343339383037/temperature?access_token=89d67f062abf6d45aa95f176642479d7caf5ca3c
```

Abbiate cura di sostituire: 

- 420026001147343339383037 con il vostro device ID
- 89d67f062abf6d45aa95f176642479d7caf5ca3c con la vostra access_token

Copiando e incollando la stringa così composta nel vostro browser dovreste ottenere una risposta come la seguente:

```
{
    "cmd": "VarReturn",
    "name": "status",
    "result": 21.6,
    "coreInfo": {
        "last_app": "",
        "last_heard": "2017-09-16T12:02:34.553Z",
        "connected": true,
        "last_handshake_at": "2017-09-16T11:37:25.199Z",
        "deviceID": "420026001147343339383037",
        "product_id": 6
    }
}
```
Quello che otteniamo in risposta è una stringa che rappresenta un oggetto javascript, in formato JSON.

L'oggetto ha diverse proprietà, tra cui ```result```, in questo esempio pari a 21.6, che sono i gradi centigradi di temperatura presenti nella stanza in cui si trova Rotilio Maker.

Provate a sostituire ```temperature``` con altre variabili come ```tempsetup``` e così via, per vedere che valori vengono resituiti dal Rotilio Maker.

#### Cosa può andare storto

Se non ottenete la giusta risposta dal vostro Rotilio Maker, vi consigliamo di controllare:

- la correttezza dell'access_token e del device ID
- che il Rotilio Maker sia connesso correttamente al Cloud, controllate quindi il colore del LED, deve essere azzurro evanescente, come un respiro.
- che il vostro computer sia connesso ad Internet
- le impostazioni di eventuali firewall, che potrebbero bloccare alcune porte in uscita utilizzate dal Photon per comunicare con il Cloud di Particle.io (questo solitamente se state provando il tutto connessi ad una rete aziendale ben protetta)

Ecco una lista di porte TCP che vanno aperte in uscita, verso l'indirizzo di rete corrispondente a: ```api.particle.io```

```
5683
16384
16385
16386
```

[< Componenti principali](step-01-componenti-principali.md) | [Invio comandi >](step-03-invio-comandi.md)
