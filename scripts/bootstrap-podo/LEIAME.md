# Bootstrap isolado (.podo-bs)

`podo.scss` gera `force-app/main/default/staticresources/bootstrap_podo.css`: Bootstrap 5.3.3 só com CSS,
todas as regras dentro de `.podo-bs` (nada vaza para o resto do Salesforce).

Para regenerar (em uma pasta temporária):
1. `npm install bootstrap@5.3.3 sass@1.77.8` e copie `podo.scss` para lá.
2. `npx sass --quiet --quiet-deps --style=compressed podo.scss out.css`
3. Troque `.podo-bs :root,.podo-bs [data-bs-theme=light]` por `.podo-bs` e acrescente no início
   `.podo-bs,.podo-bs *,.podo-bs ::before,.podo-bs ::after{box-sizing:border-box}`.
