import http from 'k6/http';
import { check, sleep } from 'k6';

// Configuración de la carga: Simulamos usuarios llegando
export const options = {
  stages: [
    { duration: '10s', target: 20 }, // Calentamiento: subir a 20 usuarios
    { duration: '30s', target: 50 }, // Carga: mantener 50 usuarios concurrentes
    { duration: '10s', target: 0 },  // Enfriamiento
  ],
};

export default function () {
  // ATENCIÓN: Usamos la IP dinámica de tu WSL y el puerto de Fabio (9999)
  const ip = '172.25.212.178'; 
  const port = '9999';
  
  const res = http.get(`http://${ip}:${port}/api`);

  // Validamos que responda 200 OK y que el JSON tenga contenido
  check(res, {
    'status is 200': (r) => r.status === 200,
    'node ID present': (r) => r.body.includes('node'),
  });

  sleep(1);
}