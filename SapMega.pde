//inicialmente lembre de gravar no arduino o codigo do exemplo->firmata->StandarFirmata
import processing.serial.*; //duas bibliotecas basicas
import cc.arduino.*;

import controlP5.*; // para as caixas de texto

import java.io.File;  // para arquivo essas 5 bibliotecas.
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.PrintWriter;

import java.util.Date; //para salvar no config.txt os milésimos de segundos do dia desde 1970.
//import java.util.Calendar;
import java.text.DateFormat; //para separar os campos de horas e data.


ControlP5[] textbox={null,null,null,null,null,null}; //um textbox para cada saida 
ControlP5 botao_set; //botao para setar os dados nos temporizadores.
ControlP5 indicador_entrada; //todas as entradas, amarelo para lendo sinal e escuro para nao lendo sinal. o valor sera a quantidade de segundos por janela.
ControlP5 janela;//janela de tempo

Arduino arduino; //cria o objeto arduio de comunicacao
int[] saida = {2,3,4,5,6,7};  //vetor com 6 saidas que serao os pinos de 2 a 7.
int[] estado_saida = {Arduino.LOW,Arduino.LOW,Arduino.LOW,Arduino.LOW,Arduino.LOW,Arduino.LOW}; //estado de todas as saidas será baixo (ou seja, zero)
int[] segundos_claro={0,0,0,0,0,0}, segundos_escuro={0,0,0,0,0,0}; //quantidade de segundos em claro e em escuro transformado a partir dos campos preenxidos pelo usuário
int[] entrada = {8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53}; //vetor com 46 entradas que serao os pinos de 8 a 53.
int[] cont_entrada = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}; //vetor com o contador de movimentos das entradas
int[] entrada_analogica= {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}; //vetor com entradas analógicas
int[] cont_entrada_analogica = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}; //conta os movimentos das entradas analógicas
float seg; //armazena a quantidade de segundos (verificará se mudos o segundo do dia ou não)
int[] segundos={0,0,0,0,0,0}; //segundos para cada porta mudar de estado 

int tamanho_janela=300; //tamanho inicial da janela (padrão de 5 minutos ou 300 segundos)

void setup(){
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[2], 57600); //conexao com o arduino pela serial. Pode-se colocar o caminho direto.
  for(int i=0;i<6;i++) arduino.pinMode(saida[i], Arduino.OUTPUT); //configura as portas do arduino como saida
  for(int i=0;i<46;i++) arduino.pinMode(entrada[i], Arduino.INPUT);
  size(800,600); //tamanho da janela
  seg=second(); //inicia a variavel segundos com os segundos atuais
  
  //Iniciar a parte para desenhar na tela
  //PFont font = createFont("arial",10);
  for(int i=0;i<6;i++) textbox[i] = new ControlP5(this); //cria o controlador de caixas de texto e botoes
  Desenha_Saida(textbox[0],5,15, "d2");
  Desenha_Saida(textbox[1],135,15, "d3");
  Desenha_Saida(textbox[2],265,15, "d4");
  Desenha_Saida(textbox[3],395,15, "d5"); 
  Desenha_Saida(textbox[4],525,15, "d6");  
  Desenha_Saida(textbox[5],655,15, "d7");
  
  botao_set = new ControlP5(this); //cria o botao set
  botao_set.addButton("set")
     .setPosition(250,120)
     .setSize(250,50)
     .setColorBackground(color(255,0,0)) //cor do fundo vermelha
     //.setColorLabel(color(0, 0, 0)) //igual a .setColor
     //.setColorForeground(color(0,255,0)) //cor quando coloca o mouse em cima
     //.setColorActive(color(0, 0, 255)) //cor quando pressiona o mouse
     .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
     .setColor(color(255,255,255)) //cor do texto branca
     ;  
  
  indicador_entrada = new ControlP5(this); //cria o visualizador de entradas
  for(int i=0;i<46;i++){
    indicador_entrada.addNumberbox("d"+str(i+8)) //entradas digitais
      .setPosition(10+(i%10)*50,250+50*int(i/10))
      .setSize(30,30)
      .setColorBackground(color(0,0,0))
      .setDecimalPrecision(0)
      .setColorLabel(color(0,0,255))
      .setColorForeground(color(255,255,150))
      .setColorValue(color(0,255,0))
      ;
  }
  for(int i=0;i<16;i++){
    indicador_entrada.addNumberbox("a"+str(i))  //entradas analogicas
      .setPosition(10+(i%10)*50,500+50*int(i/10))
      .setSize(30,30)
      .setColorBackground(color(0,0,0))
      .setDecimalPrecision(0)
      .setColorLabel(color(0,0,255))
      .setColorForeground(color(255,255,150))
      .setColorValue(color(0,255,0))
      ; 
  }
  janela = new ControlP5(this); //cria campo com tamanho da janela
  janela.addNumberbox("tamanho_janela(s)") 
    .setPosition(700,550)
    .setSize(30,15)
    //.setColorBackground(color(0,0,0))
    .setDecimalPrecision(0)
    //.setColorLabel(color(0,0,255))
    //.setColorForeground(color(255,255,150))
    //.setColorValue(color(0,255,0))
    .setValue(300)  //Janela default de 5 minutos
    .setRange(5,3600) //de 1 minuto à 1 hora de janela
    //.getValueLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0)
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE)
    ; 
    //janela.getController("tamanho_janela(s)").getValueLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0); // testar nos outros
    
  Carregar_Config(); //carrega configuracoes salvas. (sempre salva configuracoes quando set() for pressionado)
  Salvar_Log(); //salvar data e hora do reinicio em LOG.txt 
}

void draw(){
  if(seg!=second()){ //caso mude o segundo
    seg=second();
       //reforço para setar como entrada os pinos de entrada (no windows so funcionam assim, no MAC nao testei sem.)
    for(int i=0;i<46;i++) arduino.pinMode(entrada[i], Arduino.INPUT);
    
    for(int i=0;i<6;i++){ //decrementa o contador de cada saida e verifica se esta no momento da transicao de claro-escuro
      if(segundos[i]>0) segundos[i]--;
      if(segundos[i]<=0 && segundos_claro[i]>0 && segundos_escuro[i]>0) Altera(i);
      textbox[i].get(Numberbox.class,"seg-d"+str(i+2)).setValue(segundos[i]); //escreve no "seg_d*" o numero de segundos que falta para alterar claro-escuro.
    } 
    for(int i=0;i<46;i++){//ler entradas e altera os contadores das entradas digitais
      if(arduino.digitalRead(entrada[i])!=0){ 
        cont_entrada[i]++;
        indicador_entrada.get(Numberbox.class,"d"+str(8+i)).setColorBackground(color(255,255,150));
      }
      else indicador_entrada.get(Numberbox.class,"d"+str(8+i)).setColorBackground(color(0,0,0));
      indicador_entrada.get(Numberbox.class,"d"+str(8+i)).setValue(cont_entrada[i]);
    }
    for(int i=0;i<16;i++){//ler entradas e altera os contadores das entradas ANALOGICAS
      if(arduino.analogRead(entrada_analogica[i])>300){ //o valor vai de zero à 1023, 300 é um valor intermediário
        cont_entrada_analogica[i]++;
        indicador_entrada.get(Numberbox.class,"a"+str(i)).setColorBackground(color(255,255,150));
      }
      else indicador_entrada.get(Numberbox.class,"a"+str(i)).setColorBackground(color(0,0,0));
      indicador_entrada.get(Numberbox.class,"a"+str(i)).setValue(cont_entrada_analogica[i]);
    }
    
    tamanho_janela--; //decrementa o tamanho de janela. Quando chegar em zero, salva arquivo com movimentos na janela de tempo e zera contadores.
    if(tamanho_janela<=0){
      Salvar();
      tamanho_janela=int(janela.get(Numberbox.class,"tamanho_janela(s)").getValue()); 
      for(int i=0;i<46;i++) cont_entrada[i]=0; //zerar contadores de entrada digital.
      for(int i=0;i<16;i++) cont_entrada_analogica[i]=0; //zerar contadores de entrada analogica.
            
    }
  }
  
  //altera a cor de acordo com a saida: amarelo para claro e preto para escuro.
  for(int i=0;i<6;i++){ //altera a cor de acordo com a saida: amarelo para claro e preto para escuro.
    if(estado_saida[i]==Arduino.LOW) textbox[i].get(Button.class,"d"+str(i+2)).setColorBackground(color(0,0,0));
    else textbox[i].get(Button.class,"d"+str(i+2)).setColorBackground(color(255,255,0));
  }
  
}
public void d2() { //quando o botao D2 é pressionado, chama essa funcao.  
  if(estado_saida[0]==Arduino.LOW) estado_saida[0]=Arduino.HIGH; //altera o estado do arduino
  else estado_saida[0]=Arduino.LOW;
  arduino.digitalWrite(saida[0], estado_saida[0]);
  Salvar_Config(); //Salva arquivo config.txt
}
public void d3() {
  if(estado_saida[1]==Arduino.LOW) estado_saida[1]=Arduino.HIGH; //altera o estado do arduino
  else estado_saida[1]=Arduino.LOW;
  arduino.digitalWrite(saida[1], estado_saida[1]);
  Salvar_Config(); //Salva arquivo config.txt
}
public void d4() {
  if(estado_saida[2]==Arduino.LOW) estado_saida[2]=Arduino.HIGH; //altera o estado do arduino
  else estado_saida[2]=Arduino.LOW;
  arduino.digitalWrite(saida[2], estado_saida[2]);
  Salvar_Config(); //Salva arquivo config.txt
}
public void d5() {
  if(estado_saida[3]==Arduino.LOW) estado_saida[3]=Arduino.HIGH; //altera o estado do arduino
  else estado_saida[3]=Arduino.LOW;
  arduino.digitalWrite(saida[3], estado_saida[3]);
  Salvar_Config(); //Salva arquivo config.txt
}
public void d6() {
  if(estado_saida[4]==Arduino.LOW) estado_saida[4]=Arduino.HIGH; //altera o estado do arduino
  else estado_saida[4]=Arduino.LOW;
  arduino.digitalWrite(saida[4], estado_saida[4]);
  Salvar_Config(); //Salva arquivo config.txt
}
public void d7() {
  if(estado_saida[5]==Arduino.LOW) estado_saida[5]=Arduino.HIGH; //altera o estado do arduino
  else estado_saida[5]=Arduino.LOW;
  arduino.digitalWrite(saida[5], estado_saida[5]);
  Salvar_Config(); //Salva arquivo config.txt
}

public void set() { //quando o botao SET é pressionado
  int[] segundos_transicao={0,0,0,0,0,0}; //numero de segundos calculado a partir do campo de transicao
  int segundos_atuais=0; //numero de segundos atuais
  for(int i=0;i<6;i++){
    segundos_claro[i]=int(textbox[i].get(Textfield.class,"hc").getText())*3600 + int(textbox[i].get(Textfield.class,"mc").getText())*60 + int(textbox[i].get(Textfield.class,"sc").getText());
    segundos_escuro[i]=int(textbox[i].get(Textfield.class,"he").getText())*3600 + int(textbox[i].get(Textfield.class,"me").getText())*60 + int(textbox[i].get(Textfield.class,"se").getText()); 
    segundos_transicao[i]=int(textbox[i].get(Textfield.class,"ht").getText())*3600 + int(textbox[i].get(Textfield.class,"mt").getText())*60 + int(textbox[i].get(Textfield.class,"st").getText());
    Altera(i);
  }
  
  segundos_atuais=hour()*3600+minute()*60+second();
  for(int i=0;i<6;i++){ //Ajustar os segundos para a próxima transicao.
    if(segundos_transicao[i]>0 && segundos[i]>0){
      if(segundos_atuais<=segundos_transicao[i]) segundos[i]=segundos_transicao[i]-segundos_atuais; 
      else segundos[i]=segundos_transicao[i]+86400-segundos_atuais; 
      int st,mt,ht; //ajusta os campos ht,mt e st da transicao utilizando o numero de segundo para a próxima transicao.
      ht=segundos[i]/3600;
      mt=(segundos[i]-ht*3600)/60;
      st=segundos[i]-3600*ht-60*mt + second();
      if(st>=60) {
        mt++;
        st=st-60;
      }
      mt=mt+minute();
      if(mt>=60) {
        ht++;
        mt=mt-60;
      }
      ht=ht+hour();
      if(ht>=24) ht=ht-24;
      textbox[i].get(Textfield.class,"ht").setText(str(ht));
      textbox[i].get(Textfield.class,"mt").setText(str(mt));
      textbox[i].get(Textfield.class,"st").setText(str(st));
    }
  }
  tamanho_janela=int(janela.get(Numberbox.class,"tamanho_janela(s)").getValue());
  for(int i=0;i<46;i++) cont_entrada[i]=0; //zerar contadores de entrada digital.
  for(int i=0;i<16;i++) cont_entrada_analogica[i]=0; //zerar contadores de entrada analogica.
  Salvar_Config(); //Salva arquivo config.txt
}

void Desenha_Saida(ControlP5 textbox, int x, int y, String d){
  textbox.addButton(d) //o botao D2 altera o estado da porta digial 2 do arduino quando pressionado.
     .setPosition(x,y)
     .setSize(30,30)
     .setColorBackground(color(0,0,0)) //cor do fundo
     //.setColorLabel(color(0, 0, 0)) //igual a .setColor
     //.setColorForeground(color(0,255,0)) //cor quando coloca o mouse em cima
     //.setColorActive(color(0, 0, 255)) //cor quando pressiona
     .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
     .setColor(color(0,0,255))
     ;  
  textbox.addTextfield("hc")
     .setPosition(x+35,y-5)
     .setSize(15,15)
     .setAutoClear(false)
     .setColorForeground(color(255,255,0))
     .setColorCaptionLabel(color(0,0,0))
     //.setFont(font)
     //.setFocus(true) //faz com que o cursor inicie aqui
     //.setColor(color(255,0,0))//altera a cor do texto
     ;
  textbox.addTextfield("mc")
     .setPosition(x+55,y-5)
     .setSize(15,15)
     .setAutoClear(false)
     .setColorForeground(color(255,255,0))
     .setColorCaptionLabel(color(0,0,0))
     //.setFont(createFont("arial",20))
     ;
  textbox.addTextfield("sc")
     .setPosition(x+75,y-5)
     .setSize(15,15)
     .setAutoClear(false)
     .setColorForeground(color(255,255,0))
     .setColorCaptionLabel(color(0,0,0))
     ;  
 textbox.addTextfield("he")
     .setPosition(x+35,y+25)
     .setSize(15,15)
     .setAutoClear(false)
     .setColorForeground(color(0,0,0))
     .setColorCaptionLabel(color(0,0,0))
     ;
  textbox.addTextfield("me")
     .setPosition(x+55,y+25)
     .setSize(15,15)
     .setAutoClear(false)
     .setColorForeground(color(0,0,0))
     .setColorCaptionLabel(color(0,0,0))
     ;
  textbox.addTextfield("se")
     .setPosition(x+75,y+25)
     .setSize(15,15)
     .setAutoClear(false)
     .setColorForeground(color(0,0,0))
     .setColorCaptionLabel(color(0,0,0))
     ;            
  textbox.addNumberbox("seg-"+d)
    .setPosition(x-5,y+37)
    .setSize(35,15)
    .setDecimalPrecision(0)
    ;
   textbox.addTextfield("ht")
     .setPosition(x+15,y+70)
     .setSize(15,15)
     //.setFont(createFont("arial",20))
     .setAutoClear(false)
     ;
   textbox.addTextfield("mt")
     .setPosition(x+35,y+70)
     .setSize(15,15)
     //.setFont(createFont("arial",20))
     .setAutoClear(false)
     ;
   textbox.addTextfield("st")
     .setPosition(x+55,y+70)
     .setSize(15,15)
     //.setFont(createFont("arial",20))
     .setAutoClear(false)
     ;
}

//altera o estado da porta de saida
void Altera(int i){
  if(estado_saida[i]==Arduino.LOW){
    estado_saida[i]=Arduino.HIGH; //altera o estado do arduino
    //calcula a quantidade de segundos em claro
    segundos[i]=segundos_claro[i];
  }
  else{ 
    estado_saida[i]=Arduino.LOW;
    //calcular a quantidade de segundos em escuro
    segundos[i]=segundos_escuro[i];
  }
  arduino.digitalWrite(saida[i], estado_saida[i]);
  textbox[i].get(Numberbox.class,"seg-d"+str(i+2)).setValue(segundos[i]);
  if(segundos[i]>0){
    int st,mt,ht;
    ht=segundos[i]/3600;
    mt=(segundos[i]-ht*3600)/60;
    st=segundos[i]-3600*ht-60*mt + second();
    if(st>=60) {
      mt++;
      st=st-60;
    }
    mt=mt+minute();
    if(mt>=60) {
      ht++;
      mt=mt-60;
    }
    ht=ht+hour();
    if(ht>=24) ht=ht-24;
    textbox[i].get(Textfield.class,"ht").setText(str(ht));
    textbox[i].get(Textfield.class,"mt").setText(str(mt));
    textbox[i].get(Textfield.class,"st").setText(str(st));
  }
}

void Salvar(){ //salvar os dados em arquivo com nome da data. Se o arquivo não existir, cria o arquivo. Se o arquivo existir, acrescenta ao arquivo.
  String nome_txt=str(year())+" "+str(month())+" "+str(day())+".txt";
  String linha;
  linha = str(hour())+":"+str(minute())+":"+str(second())+" ";
  for(int i=0;i<46;i++) linha=linha+str(cont_entrada[i])+" ";
  for(int i=0;i<16;i++) linha=linha+str(cont_entrada_analogica[i])+" ";
  File f= new File(dataPath(nome_txt));
  if (!f.exists()){
    File parentDir = f.getParentFile(); 
    try {
            parentDir.mkdirs(); 
            f.createNewFile();
    }
    catch(Exception e){
            e.printStackTrace();
    }
  }
  try{
            PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter(f, true)));
            out.println(linha);
            out.close();
  }
  catch (IOException e){
            e.printStackTrace();
  }
  println("Dados salvos!");
}

void Salvar_Log(){ //salvar em arquivo sempre que o programa for reiniciado.
  Date date= new Date();
  File f= new File(dataPath("LOG.txt"));
  if (!f.exists()){
    File parentDir = f.getParentFile(); 
    try {
            parentDir.mkdirs(); 
            f.createNewFile();
    }
    catch(Exception e){
            e.printStackTrace();
    }
  }
  try{
            PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter(f, true)));
            out.println(date);
            out.close();
  }
  catch (IOException e){
            e.printStackTrace();
  }
  println("LOG salvo!");
}

void Salvar_Config(){ //Config.txt terá os dados necessários para um reinicio exatamente onde deveria estar no ciclo claro-escuro. 
  String[] linha={"","","","","","",""}; //cada linha sera uma entrada: linha[0]={estado tempo_transicao tempo_claro tempo_escuro} 
                                            //e a ultima linha (linha[6]) sera o tempo da janela
  Date date= new Date();
  long tempo_transicao = date.getTime();
  for(int i=0;i<6;i++){
    linha[i]= estado_saida[i]+" "+(tempo_transicao+(segundos[i]*1000))/1000+" "+segundos_claro[i]+" "+segundos_escuro[i];  //Dividir por mil para a funcao Long.parseLong() funcionar.
  }
  linha[6]=str(janela.get(Numberbox.class,"tamanho_janela(s)").getValue());
  saveStrings("config.txt",linha);
  println("Config salvo!");
}

void Carregar_Config(){ //utiliza o arquivo Config.txt para iniciar e continuar o ciclo anteriormente iniciado.
  long tempo_transicao,tempo_atual;
  String[] linha=loadStrings("config.txt"); //carrega o arquivo em linhas
  if(linha!=null){ //se existir o arquivo config.txt
    String[] pedacos={"","","",""}; //receberá {estado tempo_transicao tempo_claro tempo_escuro} para cada saida.
    String[] hhmmss={"","",""}; //hora,minuto e segundo apos atualizacao
    String[] am_pm={"",""}; //saber se é PM ou AM
    for(int i=0;i<6;i++){
      println(linha[i]);
      pedacos=split(linha[i],' '); //quebra cada linha em pedacos
      
      if(int(pedacos[2]) > 0){ //se existir algo no tempo_claro, atualiza hc, mc e sc.
        int seg_claro= int(pedacos[2]);
        textbox[i].get(Textfield.class,"hc").setText(str(seg_claro/3600));
        seg_claro -= (int(seg_claro/3600)) * 3600;
        textbox[i].get(Textfield.class,"mc").setText(str(seg_claro/60));
        seg_claro -= (int(seg_claro/60)) * 60;
        textbox[i].get(Textfield.class,"sc").setText(str(seg_claro));
      } 
      if(int(pedacos[3]) > 0){ //se existir algo no tempo_escuro, atualiza he,me,se.
        int seg_esc= int(pedacos[3]);
        textbox[i].get(Textfield.class,"he").setText(str(seg_esc/3600));
        seg_esc -= (int(seg_esc/3600)) * 3600;
        textbox[i].get(Textfield.class,"me").setText(str(seg_esc/60));
        seg_esc -= (int(seg_esc/60)) * 60;
        textbox[i].get(Textfield.class,"se").setText(str(seg_esc));
      }
      
      Date agora = new Date();
      tempo_atual = (agora.getTime())/1000; //.getTime retorna em milésimo de segundo, então tempo_atual terá o número de segundos até agora.
      tempo_transicao=(Long.parseLong(pedacos[1])); //tempo em segundos da próxima transição.
      int cont=0; //conta as vezes que alterou o sinal 
      if(int(pedacos[2])!=0||int(pedacos[3])!=0){ //se existir algo em claro ou em escuro, carrega campo transicao.
        while(tempo_transicao<=tempo_atual && cont<10000){//caso a proxima transicao seja menor do que a hora atual e o periodo desligado seja menor do que 10000 transicoes
          if(int(pedacos[0]) == 0){ //se estiver escuro
            if(cont%2==0) tempo_transicao+=int(pedacos[2]);//se estive escuro, some o periodo de "claro"
            else tempo_transicao+=int(pedacos[3]); //se estive claro, some o periodo de "claro"
          }
          else{
            if(cont%2==0) tempo_transicao+=int(pedacos[3]);
            else tempo_transicao+=int(pedacos[2]);
          }
          cont++;        
        }
        //carregar a novo período de transiçao em ht,mt,st.
        Date date = new Date(tempo_transicao*1000); 
        DateFormat hora = DateFormat.getTimeInstance();
        hhmmss=split(hora.format(date),':');
        
        if(hhmmss[2].length()>2){ //caso nao esteja no formato 24h. ou seja, existe PM ou AM no fim do vetor.
          am_pm=split(hhmmss[2],' ');
          if(am_pm[1].equals("PM") && !hhmmss[0].equals("12")) hhmmss[0]=str(int(hhmmss[0])+12); //Para Windows
        }
        textbox[i].get(Textfield.class,"ht").setText(hhmmss[0]);
        textbox[i].get(Textfield.class,"mt").setText(hhmmss[1]);
        textbox[i].get(Textfield.class,"st").setText(hhmmss[2]);
        //inicia com claro ou escuro. Como o botão set() será pressionado, devo iniciar com valores invertidos.
        if((cont%2)==1) estado_saida[i]=int(pedacos[0]); //se cont for impar, não preciso alterar o sinal.
        else if(int(pedacos[0])==0) estado_saida[i]=1;  // se cont for par, preciso alterar o sinal.
        else estado_saida[i]=0;
        println(hora.format(date));  
      }
      else{
        if(int(pedacos[0])==0) estado_saida[i]=1; //sempre inverte uma vez a luz para manter igual a como estava quando vier o set().
        else estado_saida[i]=0;
      }   
    }
    janela.get(Numberbox.class,"tamanho_janela(s)").setValue(Float.parseFloat(linha[6]));//atualiza o tamanho da janela para salvar
    set(); //atualiza dados e inverte luzes.
  }
}
  

  
