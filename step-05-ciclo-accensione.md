[Rotilio thermo - termostato open source](README.md) passo 5 di 7 

## Proteggiamo il ciclo di accensione e spegnimento

Per evitare accensioni e spegnimenti troppo frequenti, possiamo introdurre una variabile che tenga conto dell'ultima volta che abbiamo fermato la caldaia, chiamando la funzione ```resetRelais```.

In questo caso può tornare utile la funzione ```Time.now()``` che restituisce un intero che rappresenta il numero di secondi trascorsi dall'avviamento dall' 1/1/70.

Ad ogni chiamata della funzione ```resetRelais``` possiamo memorizzare questo numero in una variabile, così, nel momento in cui decideremo di accendere chiamando la funzione ```setRelais``` possiamo decidere di proseguire o meno nell'invio del comando al relè, la volta successiva se non sono trascorsi almeno N secondi.

Vediamo come modificare la funzione ```setRelais``` e la funzione ```resetRelais``` in modo che lavorino nei corretti intervalli di tempo.



```
int lastTimeRelaisWasReset = 0 ;      // when the Relais was set 
#define MIN_SECONDS_RELAIS_SET 120  // two minutes before setting relais again

void relaisSet(){
    
    // calculate seconds passed from last time relais was resetted
    int deltaSeconds = Time.now() - lastTimeRelaisWasReset ;
    if (deltaSeconds < MIN_SECONDS_RELAIS_SET) {
        // if not time is passed enough
        waitingForRelaisSet = true ; // yes, we are waiting for setting the relais
        return ; // exit function without setting relais
    }
    
    // we can set ralais position
    
    waitingForRelaisSet = false ;       // no, we are not waiting to set relais 
    
    digitalWrite(D7,HIGH);    // signal on Photon led that relais is SET (Position A)
	digitalWrite(D4,HIGH);    // set PIN D4 high
	delay(100);				  // waits for 100 milliseconds
	digitalWrite(D4,LOW);     // set PIN D4 low
}

void relaisReset(){
    
    lastTimeRelaisWasReset = Time.now() ; // store seconds last time we set relais
    
    digitalWrite(D7,LOW);     // signal on Photon led that relais is RESET (Position B)
	digitalWrite(D3,HIGH);    // set PIN D3 high
	delay(100);               // waits for 100 milliseconds
	digitalWrite(D3,LOW);     // set PIN D3 low
	
}

```

Per poter comunicare verso l'esterno che il relais dovrebbe portarsi in posizione A ma che stiamo aspettando per farlo, aggiungiamo alla funzione ```setup``` la pubblicazione della variabile ```waitingForRelaisSet```

```
bool    heaterOn            = true  ;    // running mode
double  T                   = 0.0   ;    // temperature from sensor °C
double  Ts                  = 18.0  ;    // temperature setup °C
int     period              = 30000 ;    // milliseconds between each loop
int     relaisAorB          = 0     ;    // relais position: A=1, B=0, default B
bool    waitingForRelaisSet = false ;  // if the relais needs to be setted and we are waiting the right time

void setup(){
    
    temperatureHistoryInit() ;

	Particle.variable("heateron",heaterOn);
	Particle.variable("temperature",T);
	Particle.variable("tempsetpoint",Ts);
	Particle.variable("relaisaorb",relaisAorB);
	Particle.variable("waitrelais",waitingForRelaisSet) ;

	Particle.function("setheater",setHeaterMode) ;
	Particle.function("settemp",setTempSetpoint) ;
	
	pinMode(D3,OUTPUT);
	pinMode(D4,OUTPUT);
	
	pinMode(D7,OUTPUT);
	
	digitalWrite(D4, LOW);
    digitalWrite(D3, LOW);  

	Wire.begin();
}
```

Potete scaricare il codice modificato con la protezione delle accensioni, cliccando qui: [rotiliothermo_step05.ino](https://github.com/techmakers/rotiliothermo/blob/master/firmware/rotiliothermo_step05.ino).

Nota bene: dato che all'avviamento potrebbe essere chiamata la funzione ```relaisReset```, anche la prima accensione verrà quindi "protetta", non potendo così avvenire se non trascorsi i due minuti.

Da questo momento in avanti per sapere se il relais è realmente in posizione A, occorre quindi leggere entrambe le variabili ```relaisAorB``` e ```waitingForRelaisSet```.

Se ```waitingForRelaisSet``` è vera allora il relè è sicuramente in posizione B, indipendentemente dal valore di ```relaisAorB```.

Un effetto collaterale positivo che otteniamo con questa ultima modifica di protezione dell'accensione è anche la protezione del sistema dai seguenti casi:

- utente che modifica, potremmo dire "gioca con", le impostazioni del sistema cambiandole molto rapidamente
- più utenti, connessi allo stesso sistema, che ignari modificano le impostazioni in rapida successione

Il caso potrebbe essere quello in cui due componenti (X e Y) della famiglia impostano il riscaldamento.
Supponiamo che Y decida di spegnere il riscaldamento e che trenta secondi dopo X decida di riaccenderlo, ecco che il relè verrebbe prima resettato (posizione B) e poi settato (posizione A), questo giochino, ripetuto N volte potrebbe dare problemi all'impianto.

La protezione appena introdotta risolve questo problema, ma non solo, ci proteggerà anche da eventuali errori dell'APP che andremo a costruire per pilotare da remoto il nostro impianto di riscaldamento.

[< Lettura temperatura](step-04-lettura-temperatura.md) | [Evento sul cloud >](step-06-evento-su-cloud.md)