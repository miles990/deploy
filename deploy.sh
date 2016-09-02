#!/bin/sh

# 參數
NAME=lobby
WORKSPACE=/tmp/$NAME
BIN=Lobby.exe
EXPORT=export # 輸出
PORT=5002

# 移除舊的 export folder
rm -rf $EXPORT
mkdir -p $EXPORT

# 複製檔案到 export folder
cp -a Lobby/bin/Debug/*.dll $EXPORT
cp -a Lobby/bin/Debug/Lobby.exe $EXPORT

#echo "compiling ..."
# 合併 dll 跟 exe 檔
#./ILMerge.exe /targetplatform:"v4,C:\Windows\Microsoft.NET\Framework\v4.0.30319" /out:$EXPORT/Lobby.exe $EXPORT/Lobby.exe $EXPORT/*.dll
#rm -rf $EXPORT/*.dll
#echo "finished!!!"

# 建立 run.sh 到 export folder (執行環境)
touch $EXPORT/run.sh && \
echo '#!/bin/sh' > $EXPORT/run.sh && \
echo "docker run --rm -it --name ${NAME} \
	-p ${PORT}:${PORT} \
	-v ${WORKSPACE}:${WORKSPACE} \
	mono:4.4.2 \
	mono ${WORKSPACE}/${BIN}" >> $EXPORT/run.sh

# 打包 export folder
cd $EXPORT && tar zcvf ../$NAME.tar.gz * && cd ..

# ssh 到 remote，刪除舊的 workspace
touch script && \
echo "rm -rf ${WORKSPACE}" > script && \
echo "mkdir -p ${WORKSPACE}" >> script

./putty.exe -pw 70444999 -ssh omg@172.16.18.63 -m script

# 上傳檔案到 remote workspace
./pscp.exe -pw 70444999 -scp $NAME.tar.gz omg@172.16.18.63:$WORKSPACE

# 解開打包檔案到指定目錄，並透過 tmux 執行程式
echo "tar zxvf ${WORKSPACE}/${NAME}.tar.gz -C ${WORKSPACE}" > script && \
echo "tmux kill-session -t ${NAME}" >> script && \
echo "tmux new -d -s ${NAME}" >> script && \
echo "tmux send-keys -t ${NAME} 'docker rm -f ${NAME}' C-m" >> script && \
echo "tmux send-keys -t ${NAME} '${WORKSPACE}/run.sh' C-m" >> script && \
echo "rm -rf ${WORKSPACE}/${NAME}.tar.gz" >> script;

./putty.exe -pw 70444999 -ssh omg@172.16.18.63 -m script

# 移除暫存檔案
rm -rf script && \
rm -rf ${NAME}.tar.gz