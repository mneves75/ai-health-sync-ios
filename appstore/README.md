# App Store — HealthSync Helper App

Metadados, páginas e guias para submissão na App Store no formato **Fastlane `deliver`**.

## Estrutura

```
appstore/
├── README.md                          <- Você está aqui
├── metadata/
│   ├── copyright.txt                  "2026 Marcus Neves"
│   ├── primary_category.txt           HEALTH_AND_FITNESS
│   ├── secondary_category.txt         UTILITIES
│   ├── default/                       Compartilhado entre idiomas
│   │   ├── name.txt                   Nome do app (21 chars)
│   │   ├── privacy_url.txt            URL da política de privacidade
│   │   ├── support_url.txt            URL da página de suporte
│   │   └── marketing_url.txt          URL do repositório GitHub
│   ├── en-US/                         Inglês (EUA)
│   │   ├── subtitle.txt               28 chars
│   │   ├── keywords.txt               97 chars
│   │   ├── description.txt            ~1.600 chars
│   │   ├── promotional_text.txt       ~120 chars
│   │   └── release_notes.txt          v1.0.0
│   ├── pt-BR/                         Português (Brasil)
│   │   ├── subtitle.txt               26 chars
│   │   ├── keywords.txt               99 chars
│   │   ├── description.txt            ~1.700 chars
│   │   ├── promotional_text.txt       ~140 chars
│   │   └── release_notes.txt          v1.0.0
│   └── review_information/            Info para equipe de revisão Apple
│       ├── first_name.txt
│       ├── last_name.txt
│       ├── email_address.txt
│       ├── phone_number.txt           TODO: Adicionar número de telefone
│       ├── notes.txt                  Instruções de teste para o reviewer
│       ├── demo_user.txt              (vazio — sem login)
│       └── demo_password.txt          (vazio — sem login)
├── pages/                             Páginas HTML standalone para hospedagem
│   ├── privacy-policy.html            Responsiva, dark mode, LGPD/GDPR/CCPA
│   └── support.html                   FAQ + requisitos + contato
└── screenshots/
    └── README.md                      Guia de produção de screenshots
```

## Checklist de Submissão

### Antes da Primeira Submissão

- [ ] Adicionar número de telefone em `metadata/review_information/phone_number.txt`
- [ ] Hospedar `pages/privacy-policy.html` (ex: GitHub Pages)
- [ ] Hospedar `pages/support.html` (ex: GitHub Pages)
- [ ] Atualizar URLs em `metadata/default/` se o local de hospedagem for diferente
- [ ] Produzir screenshots (ver `screenshots/README.md`)
- [ ] Criar registro no App Store Connect com bundle ID `org.mvneves.healthsync`

### Validação de Conteúdo

- [ ] **Nome:** 21 chars (limite: 30)
- [ ] **Subtítulo en-US:** 28 chars (limite: 30)
- [ ] **Subtítulo pt-BR:** 26 chars (limite: 30)
- [ ] **Keywords en-US:** 97 chars (limite: 100)
- [ ] **Keywords pt-BR:** 99 chars (limite: 100)
- [ ] **Texto promocional en-US:** ~120 chars (limite: 170)
- [ ] **Texto promocional pt-BR:** ~140 chars (limite: 170)
- [ ] **Descrição en-US:** ~1.600 chars (limite: 4.000)
- [ ] **Descrição pt-BR:** ~1.700 chars (limite: 4.000)
- [ ] Sem repetição desnecessária de keywords entre título, subtítulo e campo keywords
- [ ] Sem stop words desperdiçando espaço no campo keywords

### Conformidade HealthKit (Guidelines 2.5.1, 5.1.1, 5.1.3)

- [ ] HealthKit é funcionalidade central do app
- [ ] Dados de saúde NÃO são armazenados no iCloud
- [ ] Dados de saúde NÃO são usados para publicidade ou mineração
- [ ] Dados de saúde NÃO são compartilhados com terceiros
- [ ] Política de privacidade acessível no app e na URL de suporte
- [ ] Privacy Nutrition Labels declaradas corretamente no App Store Connect

### Upload via Fastlane

```bash
# Validar metadados sem enviar
fastlane deliver --validate_only

# Enviar metadados + screenshots
fastlane deliver --skip_binary_upload

# Submissão completa (com binário)
fastlane deliver
```

Requer configuração de `Deliverfile` e `Appfile` (não incluídos — ver docs do Fastlane).

## Estratégia ASO

Keywords otimizadas com pesquisa 2025-2026:

- "HealthSync" NÃO se decompõe na busca da Apple — `health` e `sync` estão no campo keywords
- Stop words evitadas: sem "app", "the", "and" nas keywords
- Sem repetição entre título, subtítulo e campo keywords
- Termos long-tail incluídos: "heart rate", "no cloud"
- Termos de dispositivo omitidos: Apple indexa "iPhone", "Mac" automaticamente pela plataforma

## Hospedagem (GitHub Pages)

```bash
# Copiar páginas HTML para docs/ do GitHub Pages
mkdir -p docs
cp appstore/pages/privacy-policy.html docs/
cp appstore/pages/support.html docs/

# Habilitar GitHub Pages: Settings > Pages > Source: branch main, pasta /docs
# URLs ficam:
# https://mneves75.github.io/ai-health-sync-ios/privacy-policy.html
# https://mneves75.github.io/ai-health-sync-ios/support.html
```

## Referência de Arquivos-Fonte

| Arquivo | Usado Para |
|---------|-----------|
| `PrivacyPolicyView.swift` (linhas 7-42) | Texto-base da política de privacidade |
| `HealthDataType.swift` (31 cases) | Contagem e nomes dos tipos de dados |
| `DOCS/TROUBLESHOOTING.md` | Conteúdo do FAQ na página de suporte |
| `DOCS/assets/screenshots/` | 2 screenshots brutos existentes |
| `README.md` | Lista de funcionalidades e tagline |