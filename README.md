# Reflow 

[Reflow](https://reflowproject.eu) is an EU Horizon 2020 research project running from 2019-2022, which aims to enable the transition 
of European cities towards circular and regenerative practices. More specifically, REFLOW uses Fab Labs 
and makerspaces as catalysers of a systemic change in urban and peri-urban environments, which enable, 
visualize and regulate “four freedoms”: free movement of materials, people, (technological) knowledge and 
commons, in order to reduce materials consumption, maximize multifunctional use of (public) spaces and 
envisage regenerative practices. The project will provide best practices aligning market and government needs 
in order to create favourable conditions for the public and private sector to adopt circular economy (CE) 
practices. REFLOW is creating new CE business models within six pilot cities: Amsterdam, Berlin, ClujNapoca, Milan, Paris and Vejle and assess their social, environmental and economic impact, by enabling active 
citizen involvement and systemic change to re-think the current approach to material flows in cities.

Reflow crypto and the free and open source software referenced sits at the core of the innovative developments 
in REFLOW technical work-package and implements a novel signature scheme for the specific use-case of 
material passports whose integrity, provenance and portability is granted by means of provable cryptography.

## Zero Knowledge Multi Party Signatures with Application to Distributed Authentication

Reflow crypto is a novel signature scheme supporting unlinkable signatures by multiple parties authenticated by means of zero-knowledge credentials. Reflow integrates with blockchains and graph databases to ensure confidentiality and authenticity of signatures made by disposable identities that can be verified even when credential issuing authorities are offline. We implement and evaluate Reflow smart contracts for Zenroom and present an application to produce authenticated material passports for resource-event-agent accounting systems based on graph data structures. Reflow uses short and computationally efficient authentication credentials and can easily scale signatures to include thousands of participants.

This blog post provides a simple explanation: [material passports for the circular economy](https://medium.com/think-do-tank/reflow-crypto-material-passports-for-the-circular-economy-d75b3aa63678).

# Paper

The pre-print of this paper is made available at:

- Github: [REFLOW_crypto_DYNE_D23.pdf](https://dyne.github.io/reflow-crypto/REFLOW_crypto_DYNE_D23.pdf)
- Arxiv: https://arxiv.org/abs/2105.14527
- NASA ADS: https://ui.adsabs.harvard.edu/abs/arXiv:2105.14527

# Citation

This paper can be cited using bibtex format information:

```
@article{roio2021reflow,
      title={Reflow: Zero Knowledge Multi Party Signatures with Application to Distributed Authentication}, 
      author={Denis Roio and Alberto Ibrisevic and Andrea D'Intino},
      year={2021},
      eprint={2105.14527},
      archivePrefix={arXiv},
      primaryClass={cs.CR}
}
```

# License

Reflow crypto is copyright (C) 2020-2021 by the Dyne.org foundation

The format of this document is that of an academic publication (Computer Science – Cryptography and 
Security, cs.CR) submitted to open publishing platforms and made freely available to the scientific 
community under the Creative Commons License (CC BY-NC-SA 4.0), see:

[Creative Commons — Attribution-NonCommercial-ShareAlike 4.0 International — CC BY-NC-SA 4](https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode)
