[Rotilio thermo - termostato open source](README.md) passo 4 di 7

## Stabilizzare la lettura della temperatura

### Prossimi passi

Ci sono cose che si "possono" fare, ma altre che si "devono" fare.

Quello che "possiamo" fare ad esempio potrebbe essere di pubblicare lo stato del sistema ogni volta che c'è una variazione.

Ad esempio potremmo inviare sul cloud un segnale ogni volta che il relè passa da A a B e viceversa, informando così un APP o un utente.

Quello che "dobbiamo" fare sono altre cose molto importanti.

La prima cosa da fare è ottimizzare il sistema di regolazione.

Facciamo un ipotesi:

- temperatura desiderata: 23.0 °C
- temperatura rilevata: 23.0 °C

In questo caso, la temperatura rilevata è pari a quella desiderata, il relè sarà quindi in posizione B.

La risoluzione della lettura del nostro sensore è di 0.1 °C.

Se al loop successivo (30 secondi dopo) la temperatura è scesa di 0.1°C il nostro sensore la rileva e il relè passa in posizione "A" per iniziare a scaldare.

Se dopo altri 30 secondi, altro loop, la temperatura risale di 0.1°C e torna quindi a 23.0°C ecco che il nostro relè torna in posizine B.

Se la temperatura rilevata continua ad oscillare di 0.1°C rischiamo di accendere e spegnere il riscaldamento ogni 30 secondi, rischiando di:

- danneggiare la calderina
- sprecare energia, quindi gas

Occorre trovare una soluzione al problema, ma facciamo una piccola riflessione.

Il sistema che stiamo costruendo è un sistema a retroazione.

Il feedback è dato dalla temperatura rilevata. L'errore è la differenza tra temperatura desiderata e temperatura rilevata.

Se l'errore è > 0 allora chiudiamo il circuito di controllo della calderina, altrimenti lo apriamo.

La nostra regolazione è a due stati discreti, senza valori intermedi.
Per questo, la teoria della regolazione, tanto ben illustrata in questo interessante documento [http://www.unife.it/ing/lm.meccanica/insegnamenti/dinamica-controllo-diagnosi-di-sistemi-b/materiale-didattico/Controllori_PID.pdf](), non è applicabile.

Quello che però possiamo fare però sono due cose:

1. stabilizzare la lettura della temperatura, in modo da evitare oscillazioni non volute, dovute a: instabilità del sensore, apertura di finestre vicino al sensore, passaggi di cose molto calde vicino al sensore e così via.

2. proteggere il ciclo di accensione e spegnimento introducendo dei ritardi in modo da impedire l'accensione subito dopo uno spegnimento.

### Stabilizzare la lettura della temperatura

La cosa più semplice per raggiungere questo obiettivo è quella di calcolare la temperatura media di un periodo di tempo, così da rilevare reali variazioni significative della temperatura.

Un buon sistema è quello di tenere in memoria le ultime N letture di temeperatura e usare la media di queste letture come valore in ingresso alla funzione di regolazione.

Occorre quindi:

1. predisporre un array di ```double``` dove memorizzare le ultime N letture
2. modificare la funzione di lettura temperatura che: 
	1. scali (shiftare) le temperature indietro di una posizione ad ogni nuova lettura
	2. memorizzi la nuova nell'ultima posizione
	3. calcoli la media e la memorizzi nella variabile ```T```

Ipotizzando di eseguire la media su 10 letture, con un loop di 30 secondi, il valore medio della temperatura corrisponderà alla media degli ultimi 300 secondi, ovvero cinque minuti.

Con un po' di sperimentazione si arriverà a capire se 10 letture sono troppe (sistema troppo lento) o troppo poche (sistema troppo sensibile).

Dipende molto dalla velocità con cui l'ambiente si scalda o si raffredda.

Vediamo di seguito un implementazione possibile.

Primo punto, predisponiamo l'array dove andremo a memorizzare le ultime 10 temperature

```
#define READINGS_COUNT 10        // here we can setup the number of readings we want to store
#define BLANK_VALUE -9999        // this will be used to fill the temperature history array with a known initial value 
double temperatureHistory[READINGS_COUNT] ; // here we will store the temperature history
```

Predisponiamo anche la funzione che inizializza il nostro array

```
// this will be called in the setup or every time we want to clean the temperature history reading
void temperatureHistoryInit(){
	for (int i = 0; i < arraySize(temperatureHistory); i++) {
  		temperatureHistory[i] = BLANK_VALUE ;
	}
}
```

Questa è la funzione che memorizza la temperatura nell'array.

Alla prima lettura di, ad esempio 20°C, il nostro array sarà una cosa del genere:

```
20,20,20,20,20,20,20,20,20,20
```
Alla seconda lettura di, ad esempio 20.5 °C, il nostro array sarà una cosa del genere:

```
20,20,20,20,20,20,20,20,20,20.5
```

Alla terza lettura, di 20.6, avremo quindi:

```
20,20,20,20,20,20,20,20,20.5,20.6 
```

```
void temperatureHistoryStore(double t){

	int lastIndex = READINGS_COUNT - 1 ;

	// the first time this function will run, we fill the array with the new t value
	for (int i = 0; i <= lastIndex; i++) {
  		if (temperatureHistory[i] == BLANK_VALUE) temperatureHistory[i] = t ;
	}

	// shift all the elements to the left, loosing the first one each time
	for (int i = 0; i < lastIndex; i++) {
  		temperatureHistory[i] = temperatureHistory[i+1] ;
	}

	// store new temperature in the last array position
	temperatureHistory[lastIndex] = t ;

}
```

La funzione che calcola la media delle 10 temperature

```
double temperatureHistoryCalcAverage(){
	
	// sum all values in the array
	double tempSum = 0 ;
	for (int i = 0; i < READINGS_COUNT; i++) {
	    double t = temperatureHistory[i] ;
  		tempSum = tempSum + temperatureHistory[i] ;
	}
	
    // calulating average temperature
	double average = tempSum / READINGS_COUNT ;
	
	// returning rounded value of average
	return round(average*10)/10.0 ;

}
```

infine occorre modificare la procedura di setup aggiungendo la chiamata alla funzione ```temperatureHistoryInit```, come segue:

```
void setup(){

	temperatureHistoryInit() ;

	...

}
```
per concludere, modifichiamo la funzione ```loop``` così da utilizzare le precedenti funzioni:

```
void loop(){
	
	double lastT = readTemperatureFromSensor() ;  // acquire actual temperature
	temperatureHistoryStore(lastT) ;              // store last temperature reading
	T = temperatureHistoryCalcAverage() ;         // calc temperature average
	
   [...]
   
```

Potete scaricare il codice modificato con la stabilizzazione della lettura della temperatura, cliccando qui: [rotiliothermo_step04.ino](https://github.com/techmakers/rotiliothermo/blob/master/firmware/rotiliothermo_step04.ino).

[< Invio comandi](step-03-invio-comandi.md) | [Ciclo accensione >](step-05-ciclo-accensione.md)