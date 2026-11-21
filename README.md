# Gravity Junkyard

Protótipo para Android em Godot 4.5.1 e GDScript. Controlas um pequeno planeta num pátio orbital. Toca no campo para lançar o planeta na direção do toque. A sucata próxima curva a trajetória em direção ao planeta e é recolhida ao entrar em contacto com ele.

- Cada setor termina quando atinges a meta de recolha. As metas são 14, 24 e 34 peças.
- Gasta sucata no piloto automático para procurar os detritos mais próximos e reforçar a atração. Podes intervir manualmente a qualquer momento em que o impulso esteja carregado.
- Alterna entre 1× e 2× quando quiseres acelerar a simulação. Não há tempo limite. O protótipo reinicia quando fechas a aplicação.

## Debian amd64

Executa os comandos seguintes como `root`, como no teu Debian. Podes usar a instalação de Java 17 do Debian 12 ou Java 21 do Debian 13. O pacote `default-jdk-headless` instala a versão apropriada para a tua distribuição.

```bash
dpkg --print-architecture
df -h /home/jorgegaspar /tmp
apt-get update
apt-get install -y git ca-certificates curl unzip python3 default-jdk-headless \
  libfontconfig1 libgl1 libxcursor1 libxi6 libxinerama1 libxrandr2 libxrender1
```

O primeiro comando deve mostrar `amd64`. Reserva cerca de 3 GB livres no disco que contém o diretório do jogo e o temporário. Se forem discos diferentes, reserva cerca de 2 GB em `/tmp` para os downloads iniciais e 1 GB no disco do projeto. Podes redirecionar o temporário com `TMPDIR=/caminho/para/diretorio` antes de executar o instalador.

### Primeira compilação

Se já tens o repositório clonado no caminho indicado, salta a linha de `git clone`.

```bash
git clone https://github.com/jorgegaspar/gravity-junkyard.git \
  /home/jorgegaspar/Tegarte_Labs/gravity_junkyard
cd /home/jorgegaspar/Tegarte_Labs/gravity_junkyard
git pull --ff-only origin main
./scripts/setup-android.sh
./scripts/build-apk.sh
```

O instalador descarrega o editor Godot, extrai só o template Android de depuração, instala Android SDK Command-line Tools, Platform-Tools e Build-Tools 35.0.0 e cria a chave de depuração. Lê a licença apresentada pelo SDK Manager e responde `y` se concordares. A exportação usa o template oficial diretamente, sem Android Studio, Gradle, NDK ou emulador. Toda a toolchain fica em `.toolchain/` no clone. Faz cópia de segurança de `.toolchain/debug.keystore` se quiseres manter a possibilidade de atualizar o APK instalado após recriar o clone.

O resultado é `build/gravity-junkyard-debug.apk`, assinado para testes em telemóveis Android 7.0 ou posterior, com processador ARM de 32 ou 64 bits. Podes copiar o ficheiro para o telemóvel e abri-lo, ou instalar por USB com a depuração USB ativa e autorizada no telemóvel.

```bash
.toolchain/android-sdk/platform-tools/adb devices
.toolchain/android-sdk/platform-tools/adb install -r build/gravity-junkyard-debug.apk
```

### A cada atualização

```bash
cd /home/jorgegaspar/Tegarte_Labs/gravity_junkyard
git pull --ff-only origin main
./scripts/build-apk.sh
```

Repete `./scripts/setup-android.sh` se a versão da toolchain mudar ou se mudares o clone de pasta. O APK de depuração destina-se a testes locais.
