[Rotilio thermo - termostato open source](README.md) passo 6 di 7

## Inviamo un evento sul cloud quando accendiamo o spegnamo il riscaldamento

Il cloud di Particle.io fornisce, oltre alla pubblicazione di variabili e funzioni, anche la pubblicazione di **eventi**.

Potete leggere un po' di documentazione in merito alla pubblicazione di eventi a questo link: [https://docs.particle.io/reference/firmware/photon/#particle-publish-]().

Per pubblicare l'evento di accensione possiamo quindi inserire nella funzione ```relaisSet``` la chiamata a funzione ```Particle.publish```, inviando un eveento denominato "relaisset".

```
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
	
	Particle.publish("relaisset");
}
```

per pubblicare l'evento di spegnimento possiamo invece inserire la chiamata ```Particle.publish``` nella ```relaisReset```, inviando un evento denominato "relaisreset".

```
void relaisReset(){
    
    lastTimeRelaisWasReset = Time.now() ; // store seconds last time we set relais
    
    digitalWrite(D7,LOW);     // signal on Photon led that relais is RESET (Position B)
	digitalWrite(D3,HIGH);    // set PIN D3 high
	delay(100);               // waits for 100 milliseconds
	digitalWrite(D3,LOW);     // set PIN D3 low
	
	Particle.publish("relaisreset"); // sends a "relaisreset" event to the cloud
	
}
```

Per ricevere gli eventi pubblicati dal dispositivo attraverso il cloud di Particle.io, utilizziamo a piacimento il browser o il programma ```curl```.

A questo url della GET http possiamo ricevere gli eventi:

```https://api.particle.io/v1/devices/36001b001551353531343431/events?access_token=cb60d9b2da2146bd7c2ede3c47f2c8523a95a825```

Abbiate cura di sostituire ID del dispositivo e ACCESS_TOKEN con i vostri.

Se utilizzate il ```curl``` in una finestra di terminale

```
curl https://api.particle.io/v1/devices/36001b001551353531343431/events?access_token=cb60d9b2da2146bd7c2ede3c47f2c8523a95a825
```

in poco tempo otterrete quanto segue

```
:ok

event: relaisreset
data: {"data":"null","ttl":60,"published_at":"2017-09-24T21:45:43.182Z","coreid":"36001b001551353531343431"}




event: relaisreset
data: {"data":"null","ttl":60,"published_at":"2017-09-24T21:46:13.298Z","coreid":"36001b001551353531343431"}




event: relaisreset
data: {"data":"null","ttl":60,"published_at":"2017-09-24T21:46:43.413Z","coreid":"36001b001551353531343431"}




event: relaisreset
data: {"data":"null","ttl":60,"published_at":"2017-09-24T21:47:13.535Z","coreid":"36001b001551353531343431"}




event: relaisreset
data: {"data":"null","ttl":60,"published_at":"2017-09-24T21:47:43.660Z","coreid":"36001b001551353531343431"}
```

Potrete quindi notare, che ogni 30 secondi, viene inviato un evento "relaisreset", si può capire dalla data del dato "published_at".

Come potrete immaginare, questo non è corretto e mette in evidenza un difetto del nostro firmware.

Le funzioni ```relaisSet``` e ```relaisReset``` vengono chiamate sempre, anche se il relè è già nella posizione giusta.

Di per sè questo non è un problema, ma causa due cose:

1. il dispositivo invia "falsi" eventi al cloud
2. le bobina del relè vengono eccitate comunque almeno ogni 30 secondi, con uno spreco di corrente che, in applicazioni alimentate a batteria, sono la fine del progetto ancor prima di iniziarlo.

Dobbiamo quindi prevenire inutili chiamate alle funzioni ```relaisset``` e ```relaisreset```.

Per fare questo dobbiamo memorizzare lo stato del relè in una variabile 
```relaisIsSet``` dichiarata all'inizio del codice, 

```
bool    relaisIsSet         = true  ;    // we will test this before really calling the relaisSet or relaisReset functions
```


impostarla correttamente ogni volta che chiamiamo le funzioni ```relaisSet``` e ```relaisReset```

```
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
	
	relaisIsSet = true ;
	
	Particle.publish("relaisset"); // sends a "relaisset" event to the cloud
}

void relaisReset(){
    
    lastTimeRelaisWasReset = Time.now() ; // store seconds last time we set relais
    
    digitalWrite(D7,LOW);     // signal on Photon led that relais is RESET (Position B)
	digitalWrite(D3,HIGH);    // set PIN D3 high
	delay(100);               // waits for 100 milliseconds
	digitalWrite(D3,LOW);     // set PIN D3 low
	
	relaisIsSet = false ; 
	
	Particle.publish("relaisreset"); // sends a "relaisreset" event to the cloud
	
}
```

e verificare nel ```loop``` lo stato della variabile prima di chiamare realmente le funzioni suddette.

```
	if (relaisAorB == 1) {
		if (!relaisIsSet) relaisSet();           // switch relais to position A
	} else {
		if (relaisIsSet) relaisReset();         // switch ralais to position B
	}
```

### Invio della teperatura attuale

Per poter aggiornare le eventuali applicazioni che andremo a sviluppare, implementiamo anche la pubblicazione della temperatura attuale, ovvero il valore contenuto nella variabile T.
Per essere certi di non inviare valori con variazioni poco significative, calcoleremo il delta tra il valore attuale e quello precedente di T, inviando un evento solo se il delta è maggiore di 0.05 °C.

```
	double newT = temperatureHistoryCalcAverage()+tempOffset;   // calc temperature average
	double delta = newT-T;                                      //store delta between old and new temperature
	T=newT;
	delta = (delta < 0 ? delta * -1.0 : delta);
	if (delta>0.05)
	{
	    Particle.publish("tempchanged", String(T, 1));      //publish temperature if changed
	}
 
```

Potete scaricare il codice modificato con la pubblicazione degli eventi, cliccando qui: [rotiliothermo_step06.ino](https://github.com/techmakers/rotiliothermo/blob/master/firmware/rotiliothermo_step07.ino).

Potete adesso provare a modificare le impostazioni di temperatura per testare tutto il sistema.

Se non lo avete ancora fatto, potete utilizzare la comodissima console che Particle.io mette a disposizione per testare il firmware dei dispositivi, la trovate a questo link: [https://console.particle.io/devices/]().

Si presenterà l'elenco dei device associati al vostro account Particle.io (lo avevate creato quando avete collegato per la prima volta un Photon alla rete WiFi).

Cliccando sul dispositivo potrete accedere all'elenco di variabili e funzioni, nonchè ricevere gli eventi pubblicati dal dispositivo stesso.

Avrei potuto indicarvi prima l'esistenza di questa utility ma ho preferito mostrarvi gli strumenti che, tramite chiamate http, saranno la base per costruire la nostra APP di controllo del riscaldamento nel prossimo tutorial.


[< Ciclo accensione](step-05-ciclo-accensione.md) | [L'app mobile >](step-07-app-mobile.md)