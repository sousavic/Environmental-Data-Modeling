# Environmental-Data-Modeling
🌍 About This Project | Sobre este Projeto

This repository contains the data and scripts used in the study "Factors Affecting the Transferability of Bioindicators Based on Stream Fish Assemblages". The analysis evaluates the impact of land use on stream integrity using bioindicators from fish assemblages. The study integrates environmental, spatial, and anthropogenic pressure data.


📰 Published Study | Estudo Publicado

This script was developed as part of the research published in:

Sousa, V., Dala-Corte, R.B., Benedito, E., Brej˜ ao, G.L., Carvalho, F.R., Casatti, L., Cetra, M., Pompeu, P.S., Súarez, Y.R., Tejerina-Garro, F.L., Borges, P.P., Teresa, F.B., 2023. Factors affecting the transferability of bioindicators based on stream fish assemblages. Sci. Total Environ. 881 (2), 163417 https://doi.org/10.1016/j. scitotenv.2023.163417.


📊  Statistical Analysis |  Estatística Avançada

This project involved complex statistical analyses to ensure robust results. The following techniques were applied:

Principal Component Analysis (PCA) to reduce dimensionality and detect patterns in environmental variables.

Community Weighted Mean (CWM) to evaluate functional diversity and its relationship with land use impact.

Generalized Linear Models (GLMs) to test relationships between bioindicators and anthropogenic pressure.

Outlier detection and removal using statistical thresholds (e.g., standard deviations, Shapiro-Wilk test).

Spatial autocorrelation tests to check for dependence between sampling sites.

Normalization and standardization of datasets for better model performance.


📂 Repository Structure | Estrutura do Repositório

/Factors-Transferability-Bioindicators
│── README.md  (Project overview | Visão geral do projeto)
│── script_analise.R  (Main analysis script | Script principal da análise)
│── dataset/  (Raw data | Dados brutos)
│── results/  (Processed data | Dados processados)
│── docs/  (Detailed data description | Descrição detalhada dos dados)
│── visualizations/  (Generated plots | Gráficos gerados)


📜 How to Use | Como Usar

Clone this repository | Clone este repositório:
```bash
git clone https://github.com/sousavic/Environmental-Data-Modeling.git
cd Environmental-Data-Modeling

Open the script_analise.R in RStudio | Abra o script_analise.R no RStudio.

Run the script to process data and generate results | Execute o script para processar os dados e gerar resultados.
install.packages(c("vegan", "dplyr", "cluster"))

📈 Results | Resultados

The processed data and generated indices (e.g., Anthropogenic Pressure Index - IPA) are stored in the results/ folder. Plots illustrating the relationships between land use and stream integrity can be found in visualizations/.



🤝 Contributing | Contribuindo

Feel free to fork this repository, submit issues, or suggest improvements.

If you want to contribute:

Fork this repository
Create a branch (git checkout -b new-feature)
Commit your changes (git commit -m "Added a new analysis step")
Push to your fork (git push origin new-feature)
Open a pull request



📧 Contact | Contato

Victoria Sousa (https://www.linkedin.com/in/victoria-sousa-34b198139/)  // victoria182sousa@gmail.com
