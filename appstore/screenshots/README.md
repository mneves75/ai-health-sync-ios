# Guia de Produção de Screenshots

## Tamanhos Obrigatórios

A App Store exige screenshots para cada classe de dispositivo:

| Dispositivo | Tamanho (px) | Obrigatório |
|-------------|-------------|-------------|
| 6.7" (iPhone 15/16 Pro Max) | 1290 x 2796 | Sim |
| 6.5" (iPhone 14/15 Plus) | 1242 x 2688 | Sim |
| 5.5" (iPhone 8 Plus) | 1242 x 2208 | Opcional (legado) |

Até 10 screenshots por idioma. Mínimo 3 recomendados.

## Screenshots Recomendados (6 slots)

| # | Tela | Legenda (en-US) | Legenda (pt-BR) | Objetivo |
|---|------|-----------------|------------------|----------|
| 1 | Tela inicial (servidor parado) | Your health data stays on your devices | Seus dados de saúde ficam nos seus dispositivos | Proposta de valor |
| 2 | Servidor ativo + QR code | Pair with one QR scan | Pareie com um escaneamento de QR | Interação principal |
| 3 | Grade de tipos de dados | 31 health data types supported | 31 tipos de dados de saúde | Amplitude de funcionalidades |
| 4 | Terminal CLI com fetch | Export to CSV or JSON from Terminal | Exporte em CSV ou JSON pelo Terminal | Apelo para power users |
| 5 | Tela de política de privacidade | Zero cloud. Zero tracking. Zero ads. | Sem nuvem. Sem rastreamento. Sem anúncios. | Confiança e privacidade |
| 6 | Tela de log de auditoria | Full audit trail of every data access | Registro completo de cada acesso | Prova de segurança |

## Assets Existentes

Dois screenshots brutos já existem em:

- `DOCS/assets/screenshots/01-server-stopped.png` — Tela inicial, servidor parado
- `DOCS/assets/screenshots/02-server-running-qr.png` — Servidor ativo com QR code visível

Podem ser usados como base para os slots #1 e #2.

## Especificações de Design

### Layout

- Moldura do dispositivo: Opcional (Apple aceita com ou sem)
- Fundo: Gradiente ou sólido — sugestão: verde Apple Health (#34C759) para branco
- Legenda: Acima ou abaixo do dispositivo, máximo 2 linhas
- Fonte: SF Pro Display Bold, 28-32pt

### Paleta de Cores

| Cor | Hex | Uso |
|-----|-----|-----|
| Verde Apple Health | #34C759 | Acento principal, fundos |
| Texto Escuro | #1D1D1F | Títulos |
| Texto Claro | #F5F5F7 | Sobre fundos escuros |
| Azul Sistema | #007AFF | Links, elementos interativos |
| Fundo | #F5F5F7 | Base modo claro |

### Tipografia

- **Títulos:** SF Pro Display Bold
- **Corpo:** SF Pro Text Regular
- **Monoespaçado (CLI):** SF Mono

SF Pro disponível em: https://developer.apple.com/fonts/

## Badge Apple

Use o badge oficial **"Works with Apple Health"** disponível em:
https://developer.apple.com/health-fitness/

Este badge pode aparecer em materiais de marketing e screenshots.

## Ferramentas

| Ferramenta | URL | Gratuita? |
|------------|-----|-----------|
| Figma | figma.com | Plano grátis |
| Rotato | rotato.app | Pago (mockups de dispositivo) |
| Screenshots Pro | screenshots.pro | Pago |
| AppMockUp | app-mockup.com | Grátis |
| Shottr | shottr.cc | Grátis (screenshots macOS) |

## Fluxo de Produção

1. Capturar screenshots brutos no simulador iPhone 16 Pro Max (6.7")
2. Criar molduras no Figma com legendas e fundos
3. Exportar em 1x, 2x, 3x para cada tamanho obrigatório
4. Salvar em `appstore/screenshots/en-US/` e `appstore/screenshots/pt-BR/`
5. Validar dimensões com: `sips -g pixelWidth -g pixelHeight *.png`

## Estrutura de Diretórios Fastlane

Após produção, colocar screenshots em:

```
appstore/screenshots/
├── en-US/
│   ├── 01-home-screen_6.7.png
│   ├── 02-qr-pairing_6.7.png
│   ├── 03-data-types_6.7.png
│   ├── 04-cli-export_6.7.png
│   ├── 05-privacy_6.7.png
│   └── 06-audit-log_6.7.png
└── pt-BR/
    ├── 01-tela-inicial_6.7.png
    ├── 02-pareamento-qr_6.7.png
    ├── 03-tipos-dados_6.7.png
    ├── 04-exportar-cli_6.7.png
    ├── 05-privacidade_6.7.png
    └── 06-auditoria_6.7.png
```

O Fastlane `deliver` detecta screenshots automaticamente pelos diretórios de idioma.