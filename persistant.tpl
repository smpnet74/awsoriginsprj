apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0001 
spec:
  capacity:
    storage: 10Gi 
  accessModes:
  - ReadWriteOnce 
  nfs: 
    path: /1
    server: ${EFSHOSTNAME} 
  persistentVolumeReclaimPolicy: Recycle