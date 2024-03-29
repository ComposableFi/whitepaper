---
papersize: a4
documentclass: article
header-includes:
    - \usepackage{multicol}
    - \usepackage{algorithm2e}
    - \newcommand{\hideFromPandoc}[1]{#1}
    - \hideFromPandoc{
        \let\Begin\begin
        \let\End\end
      }
---      


# Vision {#sec:vision}

A natural evolution in a cross-chain world entails developers and users interacting seamlessly with protocols, regardless of where their assets live or what execution type the protocol supports. Three major problems inhibit the current adoption of cross-chain DeFi by the developer community: 1) lack of trustless and secure bridging infrastructure, 2) Standardization across ecosystems (unification of contract standards) and 3) powerful, single sided messaging standards (current implementations require contracts on both layers to handle messages). 

By simplifying and unifying decentralized finance (DeFi) [@DecentralizedEthereum.org] with new interoperability standards, we accelerate DeFi into the mainstream. We are crafting a transparent, interoperable future for DeFi 2.0 and Web3. Similar to how Port Control Protocol [@PortWikipedia] became an essential piece of the networking layer for the Internet, Composable’s vision is to become the entryway and networking fabric for blockchain networks. 

The DeFi space has resorted to sharded blockchains for increased scalability [@WhyProperties], [@WhatCoinDesk]. Examples are Ethereum 2.0 [@TheEthereum.org], Polkadot [@Polkadot:Platform], and NEAR [@NEARWorld]. The result is that even though the ETH 2.0 vision is upon us, applications are sharded instead of just sharded blockchains. SushiSwap [@IntroductionSushi], for example, is deployed on multiple Ethereum Virtual Machine (EVM) [@EthereumEthereum.org] compatible chains, Layer-2-like (L2) rollups [@LayerEthereum.org], and Parachains [@WhatAlexandria], and the expansion of these applications to other ecosystems is very likely. Thus, while moving assets intra-ecosystem is becoming more intuitive, with several applications segregated within a specific ecosystem, managing assets inter-ecosystem is not [@0xbrainjarOurMedium].

We are embarking on a vast and growing opportunity in architecting and building infrastructure. Our goal is to allow developers to deploy applications capable of operating across layers and chains autonomously. 

\newpage
\tableofcontents
\newpage

\Begin{multicols}{2}

# Issues in cross-chain Infrastructure {#sec:issues-in-infra}

As new ecosystems rose in prominence during the 2020-2021 market cycle, we saw many bridging protocols rise and fall to accomodate the need for liquidity. Most (if not all) of these bridges were based on optimistic, fraud-sensitive architectures, where in essence an authority acts as an oracle. These bridges lock up certain assets on the origin chain, and mint a debt token on the destination chain, granting the holder the right to unlock the origin asset when returning the debt token. Besides asset transfers, these bridges sometimes support message passing as well, which can be used as a building block for cross-chain applications. These bridges have already proven to be security risks to DeFi, as well as difficult to build protocols on top off due to the lack of complex features provided by the message passing.

In a trusted bridging setup, we identify the following actors: 

- Relayer: pays for execution on the destination chain.
- Oracle: provides authorized mint and burn access to the contracts on origin and destination side.
- User: a contract, protocol or actual user directly interacting with the bridge. 

In this generic architecture, we choose to keep the relayer and oracle as separate actors, although in many actual implementations, these are the same entity. 

Designs used in Wormhole, Axelar and centralized exchanges use one or more accounts determine the state of the origin chain, destination chain, and based on that co-sign a message to mint/unlock funds on the destination side. 

### Trusted Bridging Recapped

We will briefly recapture the architectures of pessimistic and optimistic bridges. 

##### Pessimistic bridging {#sec:pessimisticbridging}

Pessimistic bridges require the oracle to pre-validate withdrawals, assuming that relayers will commit fraud as soon as they can.

\begin{algorithm}[H]
\SetAlgoLined
\BlankLine
\While{block has events}{
    \If{block is not final}{
        waitUntilFinal(block)
    }

    \If{block has bridge events}{
        signAndBroadcast(event)
    }
}
\caption{Oracle protocol for pessimistic trusted bridging}
\end{algorithm} 

The oracle assumes multiple responsibilities here:

1. It ensures that the event data is correct.
2. It ensures that the event data is final.

For many chains, including Ethereum, 2. cannot yet be ensured, and thus the oracle service is taking on a large risk. Usually this is reduced by waiting for a number of confirmations (blocks built on top of the current block).

From the on-chain perspective, funds are managed assuming that the oracle is honest about 1. and 2. Fraud, hacks or misconfigurations can lead to the oracle's authority being used to incorrectly release funds, as occured in Wormhole, Nomad, Raku etc...

Different protocols attempt to reduce this risk by sharding the private key using multi party computation, or simply multisig.

For a secure bridging operation, the transaction time $t$ is given by:

$$ t := t_{finality} + t_{submission} $$

where $ t_{finality} $ is the average duration for block finality, and $ t_{submission} $ the length of time of block inclusion on the destination side.

##### Optimistic bridging

Optimistic bridges such as Nomad assume that the relayer is usually honest, and fraud rarely occurs. The relayer/oracle algorithm is relatively identical to the [@sec:pessimisticbridging] algorithm. On the contract side however, the mint/unlock action is delayed, ensuring that fishermen have sufficient time to dispute the message.

Message acceptance is incredibly simple:

\begin{algorithm}[H]
\SetAlgoLined
\BlankLine
\If{message is from relayer}{
    store(message)
}
\caption{Message acceptance protocol for optimistic trusted bridges}
\end{algorithm} 

However, actually enacting the message, which leads to mints and unlocks, has a time delay, referred to as the dispute window.

\begin{algorithm}[H]
\SetAlgoLined
\BlankLine
\If{message received time is above wait threshold}{
  If{message is undisputed} {
    enact(message)
  }
}
\caption{Unlock protocol for optimistic trusted bridges}
\end{algorithm} 

Optimistic bridging trades in some advantages of pessimistic bridging, such as faster transaction times, in favour for more decentralized security. Dispute setllement remains an issue however. Usually protocols resolve to token based governance or a council.

For a secure bridging operation, the transaction time $t$ is given by:

$$ t := t_{finality} + t_{submission} + t_{dispute window} $$

where $t_{finality}$ is the average duration for block finality, $t_{submission}$ the length of time of block inclusion on the destination side, and $t_{dispute window}$ the amount of time that the relayed transaction may be disputed on the destination side.

Relayers can choose to combine $t_{finality}$ and $t_ {dispute window}$, at the risk of needing to dispute their own submissions. This improves UX but brings in a significant risk to the relayer, and in practise is not performed.

### Economic Risks in Trusted Bridging {#sec:economics-trusted-bridging}

Bridging in general brings in security risks, both on a technical level as mentioned above, and on an economic level. A wrapped token in essence is a debt obligation between the bridging protocol and the token holder, guaranteeing that on redemption of the wrapped token, the original token will be returned. The value of the wrapped token is thus the value of the underlying minus the risk of the bridging protocol not fulfilling the debt. Currently the market does not correctly price wrapped tokens (usually the valuation is equal to the underlying). This leads to a greater economic impact when a trusted bridge is unable to fulfill the debt, such as after losing the underlying in a hack.

For protocols relying on trusted bridging ecosystem, the only way to deal with this underlying economic risk is to price wrapped tokens differently. Although this mitigates economic impact, liquidity and UX suffer. It also reduces the utility of cross-chain protocols, as the actual cost of using a trusted bridge is the fee and wrapped token premium.

### Security Risks in Trusted Bridging

<!-- 
1. Censorship
2. State attackers
3. Fraud and Collusion
 -->

# Architecture Overview {#sec:overview}

<!-- 
- relayer gossip network
- IBC light client layer
- XCVM
- third party applications
 -->

# Relayer Network

<!-- 
- Monitoring
- MEV
- Block proposing integrations
 -->

# IBC Across Ecosystems

<!-- 
- Architecture for MultiConsensus IBC
- BEEFY
- Nightshade
- Aptos
 -->

# XCVM

<!-- 
1. Explain Cosmos IBC network infrastructure
2. EVM message passing
3. Gas cost of message passing + multiple round trips
 --> 

<!-- 
- XCVM Spec
- CNS
- Security
 -->

\End{multicols}


## 2.2 Paper Outline {#sec:outline}
Having covered the vision in [@sec:vision] and the roadmap in [@sec:roadmap], we now look at Composable's tech stack in a top-down approach and specify which sections throughout the Construction Paper one can find further information.

First, our Application Layer abstracts away high-level actions such as \"take out a loan on chain W layer X, then stake that on chain Y layer Z". 
We can get more abstract and say: \"take out a loan at the lowest rate and buy NFT X" where \"X" does not include any specification of the chain or layer it lives on.
Consider the application Zoom, e.g., on a Mac, which can sync and communicate seamlessly with Zoom on a PC via the internet. The user needs not to understand anything about how the internet works (besides connecting in the first place); they see the abstraction of complicated information transfers underneath, at this application layer. An application, however, in our case could be lending out money, taking a loan, committing capital to high-yield strategies, etc.

Let us descend one layer.
We believe that the application needs to be developed in an easy-to-use language for developers, blockchain agnostic. This application can help bring to life the full network effect and speed of Web3.
This is where the Cross-Chain Virtual Machine (XCVM) comes in, see [@sec:xcvm].
In other words, XCVM is a virtual machine (akin to that familiar from Ethereum) capable of running smart contracts without the need to worry about the underlying chain-connection details.
XCVM, in turn, needs to send information between various blockchains and layers.
This is where the next layer down comes into focus: The Routing Layer, see [@sec:routing-layer]. This is how the encoded information from developers is turned into the information being sent and received to and from the relevant parties.
In other words, the Routing layer is responsible for routing the information from the XCVM to the correct blockchain and the correct layer, much like Port Control Protocol [@PortWikipedia] from Web2.

To accomplish this, the Routing Layer, in turn, needs broad access to the ecosystem of blockchains.
And it needs this access to be fast and secure.
We have now arrived at our core layer: The Picasso Parachain for Kusama in [@sec:picasso-and-finality].
Incidentally, a goal is to also deploy, in a similar way, to a Polkadot parachain.
The parachain ensures security and speed as the applications transmit information around the entire ecosystem.

Taking a look now at the various existing ecosystems, for Ethereum we built Mosaic, covered in [@sec:mosaic].
Mosaic is a cross-layer bridge and allows for easy cross-layer transfers of tokens.
Mosaic is actively being built to support cross-chain transfers as well - via Picasso.
To achieve our vision for Mosaic we broke down the development into three distinct phases which we will highlight here.
In Mosaic's Phase I, [@sec:phase-i] aka the proof-of-concept (PoC), assets can be locked on the source layer, a relayer transmits the transferal information to the destination layer and the same amount in fees is released on the destination layer.
In Mosaic's Phase II, [@sec:phase-ii], we now connect multiple layers and provide multiple ways to provide liquidity on both L1 and L2.
We build a software environment, [@sec:liquidity-sim-env], to help us decide on liquidity rebalancing and an optimal fee model to use, [@sec:mosaic-fees].
In Mosaic's Phase III, [@sec:phase-iii]  we seek to increase as much as possible the decentralization of the entire system.

In addition to Mosaic, Composable is constructing a number of bridges to expand upon the  [Inter-Blockchain Communication (IBC) Protocol](https://ibcprotocol.org/) and create additional connections to the Composable ecosystem and other chains.
As the first bridge in this series, Composable has created the [Centauri Bridge](https://medium.com/composable-finance/centauri-facilitating-communication-between-interoperable-networks-5c1a997f9154) to connect the IBC Protocol (which is on the Cosmos Network) and [Picasso](https://www.picasso.xyz/), our [Kusama](https://kusama.network/) parachain.
Centauri is a trustless, final bridge that will offer the first opportunity to connect between the DotSama and Cosmos ecosystems.
While Mosaic was designed to connect to chains without light clients, Centauri is necessary to connect to chains that do have light clients installed into their runtimes.
In [@sec:lightclients], we describe light clients, their importance, and their various components.
In [@sec:mmr], we look at Merkle Mountain Ranges (MMRs) and how they can allow us to more efficiently leverage light clients in the bridging process.
Finally, in [@sec:beefy], we explain how we have combined these tools with the Bridge Efficiency Enabling Finality Yielder (BEEFY) from [Parity](https://www.parity.io/) to support a BEEFY Finality Gadget ([@sec:gadget]) and develop our own 11-BEEFY COSMOS-IBC Light Client ([@sec:beefyIbc]).
As a result, we are able to expand upon the bridging infrastructure already offered by IBC and deliver a more efficient bridge that can connect to more chains than ever before - and moreover, in combination with Mosaic, can ultimately connect all chains (whether or not they have light clients) into the Composable ecosystem.

We are also working on a number of additional developments in the Polkadot and Cosmos ecosystems [@Cosmos:Blockchains].
For Polkadot, we are creating a blockchain in Substrate [@HomeSubstrate_] and for Cosmos, we are contributing to the Cosmos SDK.
Then, pallets [@TheMedium] are used to add additional functionality - one example is our Maximal Extractable Value (MEV) [@MinerEthereum.org] resistant data oracle Apollo [@Apollo:Finance].
Other pallets can be developed including ones to enable Solidity support, cross-chain message capabilities (XCMP), decentralized exchanges, and so on.
Cosmos supports the Inter-Blockchain Communication Protocol (IBC) [@Inter-BlockchainCommunication] standard opening up for a large ecosystem that we can connect to.

In the remaining sections, we cover each of these layers in more detail and conclude at the end in [@sec:conclusion].

# 3. Cross-Chain Virtual Machine {#sec:xcvm}
The cross-chain virtual machine (XCVM) is a single, developer-friendly interface to interact and orchestrate smart contract functions across the multitude of L1 and L2 networks available.
In short, the XCVM abstracts complexity from the process of having to send instructions to the routing layer directly initiates call-backs into smart contracts and handles circuit failure such as network outages.

Build on top of our bridging infrastructure; our Composable Cross-Chain Virtual Machine tools allow developers to tap into various communication and liquidity availability functions.
The result is multifaceted; users can perform cross-chain actions, and the overarching blockchain ecosystem is repositioned as a network of agnostic liquidity and available yield.

Composable allows developers to tailor their experience to maximize for the desired parameter while minimizing ecosystem-specific decision making.

## 3.1 Architecture {#sec:architecture}
The virtual machine is, first and foremost, an abstract definition of how services should assume that cross-layer transfers and functionality operate, including security, finality, fee model, and availability.
The security and finality are dependent on the bridging technology used, and relatively static (although we will see that the security for optimistic bridges is a function of network participants and economic stake).
Fees are highly dynamic, dependent on network traffic.
Availability describes the existence of appropriate relayers and even the existence of the destination chain. Although many systems are not designed to take into account the deprecation of a blockchain, any truly resilient and scalable bridging technology must handle that failure mode.

We distinguish between two categories of bridges: optimistic and final.
Mosaic is an example of an optimistic bridging technology, using decentralized relayers, economic incentives, and dispute resolution to secure a network.
IBC and XCM are both final and require that the destination chain has a light client embedded, as well as deterministic finality.
Tendermint, GRANDPA, and BEEFY provide deterministic finality, while proof of work-based chains can only be bridged using optimistic solutions, although these solutions are highly secure in the case of Bitcoin.

Smart contracts usually assume two modes of result, success or failure, but are ill-equipped to handle partial success.
Even relatively simple layer-to-layer operations may reach an indefinite state, where contracts state or funds are left in limbo.
Instead of massively rewriting existing smart contracts and protocols to handle the multitude of failure modes, the XCVM transparently handles state transitions, disputes, and reverts.
It combines different bridging protocols, such as IBC, XCMP, and Mosaic Phase 3, and is capable of integrating new bridging technologies.
Rather than modeling a cross-chain transfer (XCT) as a single operation, such as locking funds in a local contract, we model it as a set of reversible state transitions with different approximate costs for each transition.
The VM exposes the lower-level APIs to directly query and interacts with the current state, as well as a higher-level interface, that observes the complete set as a single, fallible operation.
Sets may be combined into larger operations, allowing to roll back the entire transaction.

By modeling XCTs as a state machine, or more accurately a directed, cyclic, weighted graph, we naturally arrive at the actual requirements of the XCVM: any blockchain that is capable of executing a transition within the XCT is XCVM compatible.
Completely trustless compatibility can be achieved through the use of smart contracts and runtime-embedded light clients, such as IBC.
For chains without smart contract capabilities or light clients, such as Bitcoin, we can employ optimistic bridging and message passing technologies, such as our Mosaic project.

The XCVM offers Picasso-based decentralized Applications (dApps) different hooks and updates on the status of any XCT, as well as RBAC-based flow control for actively managing the execution of different stages.
Dapps incur transaction fees for calling into this underlying execution layer.
Depending on the stage of the XCT, this fee may be subtracted from the XCTs payload in case of a simple token transfer using our bring-your-own-gas features.

## 3.2 Well-Known Protocol Types {#sec:protocol-types}
Optimistic bridges are secured through a dispute resolution system, where relayers use a stake to provide for settlements in case of fraud.
Properly securing an XCT requires knowledge of the value of the XCT.
For token transfers, a pricing oracle may provide an estimate of the absolute stake required for a safe collateralization ratio.
We can extend this security model to decentralized finance products by providing on-chain models of common protocols.
Oracles then provide time-weighted prices and reserves, and locally we can compute the necessary collateralization to secure a sequence of DeFi operations within an XCT.
Using well-known protocol types (WKPT), we can also define how to reverse an XCT, as well as locally check the validity.

WKTPs are identified by their contract hash (for smart contract based protocols), Call definition (for XCM compatible chains) or module version (for IBC chains).
Only WKTPs used by a specific XCT incur a runtime cost.
The storage cost per WKTP ranges from a few kilobytes to hundreds, meaning that the protocol can scale to millions of WKTPs on modern hardware.
Depending on different factors, WKTPs could be effectively scaled using zero-knowledge technologies, requiring only the identifier and oracle data to be stored on-chain.

Composable dApp developers may choose to create XCTs tied to specific identifiers, or a more general, interface-based approach.
The identifier approach has better security guarantees but loses flexibility in the presence of upgradable contracts.
This distinction is necessary, as an upgradable contract can arbitrarily change semantics while binding the XCT to a specific contract hash.
Not all upgradable contracts can be uniquely identified, as keeping track of a chain of logic delegations within upgradable contracts is prohibitively expensive.
In that case, XCT authors may only use the interface-based approach.

# 4. Routing Layer Design {#sec:routing-layer}
Routing transactions between different blockchains remains a difficult problem.
Natively, blockchains have no concept of networking, DNS, or other temporal data; and storing this on-chain is both prohibitively expensive, as well as a bad idea, as temporary network outages must not cause consensus failure.
To accommodate for the limitations of blockchains, we are developing a network of decentralized nodes to provide oracle and relaying services, based on crypto-economic security primitives and threshold-signature-sharing.
Staking and fee incentives secure the network and ensure longevity.
By cleverly combining these services, we are capable of executing protocol-to-protocol interactions across chains.
In the cross-chain, cross-layer scenario we operate, it is crucial to find the best route to exploit.
A good route can reduce the time of transactions, the associated costs and minimize the risks taken by the user.
Hence, the routing layer design directly affects the quality of our service and the user experience.

Our routing layer solves two problems: constructing and maintaining a graph of the different chains and bridges available, and, finding the best route at a given time.
With the increasing number of chains (both on Layer 1 and Layer 2), and the different available bridge solutions between them, maintaining a live graph of all the connections is not a trivial task.
In a dense graph, the number of edges connecting the vertices grows quadratically.
We also need to consider the mutating and changing nature of blockchain ecosystems: new versions of protocols can be deployed, old bridges might drop support, new tokens can be added, etc.

Given the magnitude and dynamic essence of the task and the volatile prices we face, finding the optimal route for a given trade is not in most users' reach.
The problem is the Travelling salesman problem [@Gavish1978TheProblems] or the Minimum-cost flow problem [@Orlin1988AAlgorithm], with the component of changing networks the requirement of on-chain validity.
The users need to be guaranteed they got the best possible path.
We require complex algorithms (e.g.: [@Feigenbaum2005ARouting]) and dedicated heuristics to accomplish all this.

One exciting application for this execution layer is cross-chain fee management.
Our infrastructure as a whole intends to support a network of blockchain networks, meaning that there will be multiple potential pathways to the same destination.
In this scenario, without a tool to do so for them, users would have to pathfind the most efficient and compliant route for value packets.
Users may need to prioritize efficiency if the pathway must be predominantly liquid or secure or if a specific regulatory requirement must be enforced (know your customer/anti-money laundering requirements, abbreviated KYC/AML).
Therefore, the routing process would be both critical and very time-intensive.
Our pathway execution layer will simplify this process and enable users to customize which parameter they want to optimize for when completing a given transaction.

Our routing layer will abstract and simplify the route algorithms through a clean and straightforward interface.
To decentralize our solution and increase the transparency of DeFi projects, we also plan to include the following services and parties within our solution.

## 4.1 Nameservices {#sec:nameservices}
A nameservice is a simple registry that maps identifications to names (e.g: DNS).
This feature can also be used to link blockchain addresses to names (e.g: nicknames).
Nameservices improve the semantic meaning of decentralized protocols, help the inexperienced user, bridge different platforms, decrease the possibility of making errors when creating transactions, and contribute to promoting identity and digital ownership on Web3.

While other projects have already explored the benefits of using nameservices [@ProtonchainBlockchain], to the best of our knowledge, Composable Finance will be the first one to provide cross-chain and cross-layer nameservice support.
Providing nameservice support on a single chain is relatively trivial. However, maintaining nameservices across different layers and chains poses new challenges.
We will take care of the details such as key management, data synchronization, and finality on different chains so that the whole process is translucent to the final user.
Therefore, no matter the network or the token, we will support names and addresses indistinctly.

Nameservices help accomplish our vision of a less fragmented and more accessible blockchain space where a single interface allows us to leverage the composability of the DeFi space, unlocking its full potential and enabling new projects.

## 4.2 Indexers and Solvers {#sec:indexers}
As mentioned beforehand, constructing a dynamic graph and finding the best route are the main challenges our routing layer faces.
In achieving these goals, we also want to ensure the decentralization and auditability of the solution.
For this reason, we introduce two parties, which anyone can run, that will have a crucial role in the protocol:

* Indexers will act as oracles and will help to update the graph of interconnected chains and bridges. Every time there is a change in the topology of the network (new bridges/chains, network disruptions, significant changes in costs, etc.), indexers will notify it. Indexers notifications will be weighted and taken into account to update the main graph. Indexers will obtain rewards in rewards in the function of the utility of the updates and a slashing mechanism will be used to prevent malicious indexers.

* Solvers will run off-chain custom algorithms to find the best route for a given problem instance. When trying to find a path, solvers will compete to find the best solution. Received solutions will be ranked according to a predefined cost function and top solvers will earn tokens concerning the efficiency of their solution. By doing this, we leverage the game theory aspect of the competition while achieving a decentralized manner to find the best route.

![Routing architecture with indexers and solvers. We can appreciate how, by using Picasso as a finality layer, routers and indexers can collaborate on the routing algorithm. Please note how routing solver nodes leverage XCVM to propose new routes.](images/routing.png){#fig:routing}

Together with a default minimum-cost routing algorithm, these roles will address the routing challenges previously introduced.
As shown in [@fig:routing], this architecture enhances public examination and minimizes the trust users need to put on the protocol.
It is also reasonably easy to scale since most of the workload runs off-chain, while only validation is on-chain.

![Uni-connected directional graph representation of different Blockchains connected via the best bridges based on the specific requirements of a given user at a given time.](images/Selected_Bridges1.png){#fig:selbridges}

As for the routing algorithms employed by solvers, we do not enforce any restrictions.
We are interested in the best result the community can provide.
As previously mentioned, and shown in [@fig:selbridges], we are facing a complex problem with variable parameters, where there is no unique strategy that dominates the others, at least with limited time.
We outsource the pathfinding task to the decentralized community of Composable users.
As other projects have explored [@GnosisWhitepaper], having the users run different algorithms and heuristics in a fair economic game produces a better and more complete solution that can adapt to new scenarios faster.
We will also run our in-house algorithm so that all problem instances have a fair baseline solution.

# 5. Picasso and the Finality Layer {#sec:picasso-and-finality}

Composable’s vision is to create a protocol that allows for communication across ecosystems.
The result is a Port Control Protocol-like system for blockchains.
The result is multifaceted; users can perform cross-chain actions, and the overarching blockchain ecosystem is re-positioned as a network of agnostic liquidity and available yield.
Throughout these interactions, Composable allows users to tailor their experience to maximize for the desired scalar, such as security or speed, while minimizing ecosystem-specific decision making.

Foundational to our approach of expanding on existing, cutting-edge technology is our effort on stabilizing BEEFY and leading the charge on the Cosmos-Substrate bridging infrastructure.
We are developing the reference implementation for BEEFY in Golang, and the BEEFY-IBC client libraries are needed to support connections to Cosmos chains.
Only the security of a parachain allows for bridging to both XCM and IBC compatible chains.

## 5.1 Parachain {#sec:parachain}
At the core of our communication stack lies the parachain, functioning as a finality layer for IBC compatible chains, as well as a gateway into XCM compatible chains.
It functions as the incentivization layer for light client data storage and proving.

We will be pursuing the operation of both a Kusama and Polkadot parachain.
Projects that do well on the Kusama chain can then upgrade to our Polkadot parachain - still to be named.

Polkadot and Kusama also allow for native cross-chain communication with all other parachains connected to the relay chain and all external networks.
An inflationary reward mechanism is used to incentivize collators and oracles.
Through a runtime upgrade enacted by decentralized governance, the actual reward rate can be set and reduced as the protocol generates significant fees.
Users and infrastructure providers can stake PICA and LAYR tokens to grow with the ecosystem, providing critical security and capabilities to our ecosystem.

## 5.2 Picasso {#sec:picasso}
We consider Kusama and Polkadot interchangeable in what follows and part of the greater substrate ecosystem.
Polkadot offers plug-and-play security, allowing Composable to focus on building its ecosystem and leaving the security to Polkadot’s validators.
By leveraging parachains we do not have to recruit our validators for security, which gives us more excellent finality guarantees and lowers the risk of cross-chain transaction failures.

We also chose Polkadot for its blockchain development framework, Substrate.
Substrate allowed us to custom-build our blockchain, continuously upgrading our blockchain with new functionalities without needing to fork the network.
Polkadot also allows for native cross-chain communication with all other parachains connected to Polkadot and all external networks bridged to Polkadot.
Last, we believe Polkadot has the top engineering team and leadership in the industry, having been built by Gavin Wood, who coded Ethereum, invented the Solidity programming language, and developed the Ethereum Virtual Machine (EVM).
We believe Polkadot is building the third phase of crypto after Bitcoin and Ethereum.

## 5.3 Finality {#sec:finality}
Composable's support of different ecosystems implies that we must control and abstract the inclusion of transactions in other chains for the final user.
Inclusion is tightly related to the concept of finality.
Finality guarantees that past events on the blockchain are immutable; therefore, when a transaction is included on a final block, we can be sure that it has been included on the chain.

Unfortunately, complete finality cannot be provided without some compromises [@Brewer2012Cap], and most blockchains only offer some degree of finality.
We list the three degrees of finality most likely to be found on different networks, from weaker to stronger finality:

* **Probabilistic finality:** Finality is reached eventually. Under some assumptions, we can estimate the probability that a given block is considered final. With each new block added to the chain, older blocks become more final. E.g: Bitcoin and most PoW chains consider a block final after 6 blocks since the *probability* of a fork decreases exponentially as the chain grows.

* **Provable finality:** To provide stronger and faster finality, some chains include some kind of finality gadget that runs in parallel to the chain and performs come Byzantine agreement process over the blocks. Once the gadget has gone over those blocks and a consensus is reached, they are considered final. E.g: [GRANDPA](https://github.com/w3f/consensus/blob/master/pdf/grandpa.pdf){target="_blank"} on Polkadot and [Casper FFG](https://arxiv.org/pdf/1710.09437.pdf){target="_blank"} on Ethereum.
    
* **Absolute finality:** At a cost, some blockchains implement Probabilistic Byzantine Fault Tolerant (PBFT) consensus protocols. This means, once the block is crafted, it is automatically considered final (e.g: Tendermint).

We need to handle chains with different finalities and different synchronization times.
Therefore, we cannot proceed with a deterministic solution.
To make Composable decentralized and protocol-agnostic, we need to rely on validators.

## 5.4 Pallets {#sec:pallets}
Given that our parachains are the foundational layer that powers our ecosystem, we have adopted a pallet-centric approach to adding products to our parachains.
Meaning, we will offer projects the ability to deploy as pallets on our chain, with decentralized, stake-based governance, having the ability to upgrade these pallets into the runtime of our chains.
We are excited to offer this to the Kusama ecosystem and have grants programs for others to develop pallet projects using our technology to be implemented into our parachain.
Projects that do well on the Kusama chain can then upgrade to our Polkadot parachain, which we envision as the stable, more mature sister of our Kusama chain.

We intend for untrusted sources to also perform protocol-to-protocol interactions on our parachains through the web assembly-based XCVM.
Therefore, we initially focus on projects deploying as pallets, which allows these projects more granular, lower-level access to our cross-chain APIs and more advanced logic related to the block life-cycle, storage, and cryptographic primitives.

We are firm believers in security through tooling and support the move within the DeFi ecosystem towards Rust and web assembly as tools and computing platforms.

# 6. Mosaic Design {#sec:mosaic}
Mosaic is an optimistic bridging solution based on advanced liquidity management, single-sided liquidity pools, and a relayer network.
At its core, it consists of a network of bridges operated by relayers interacting with smart contracts on the source and destination chains.
Our proof-of-concept relayer solution is based on a trusted setup that monitors all connected chains for events and enacts the transfers accordingly.
The next release improves on this model by decentralizing the relayer, using different cutting-edge technologies such as Threshold-Secret-Sharing (TSS) and transaction batching using Merkle-proofs.

The liquidity layer serves to ensure liquidity is moving to the locations where it is needed, allowing the propagation of whatever instructions are required to satisfy the user’s desired outcome, as specified above.
We are currently testing this capacity within the EVM ecosystem by running our Proof of Concept (PoC) of Mosaic.
From there, we can generalize this liquidity problem and solution to other ecosystems.
Liquidity concerns are not new in DeFi.

However, they have been mainly resolved by automated market makers (AMMs) built into the popular DeFi exchanges like UniSwap and Sushiswap.
However, the introduction of cross-layer and cross-chain applications is making liquidity a more pressing issue than ever before. With so many different L2 applications and blockchains to balance liquidity and so little infrastructure, liquidity is too siloed for interoperable applications to generate meaningful value.

## 6.1 Phase I {#sec:phase-i}
Phase I presents a functional and straightforward cross-layer solution to transfer all major DeFi ecosystems.
It is a PoC with enforced limited functionality to demonstrate the capability of the system.

The main actors in this phase are:

* An L1 vault is in charge of redistributing liquidity.

* Dedicated vaults on each L2.

* Users are engaging and providing the required liquidity.

* A relayer is in charge of communicating the different supported networks.

All the actors and their interactions are depicted in [@fig:v1_mosaic].

![Polygon-Arbitrum transfer scheme in Mosaic v1.](images/mosaic/v1.png){#fig:v1_mosaic}

As you can see on [@fig:v1_mosaic], a transfer consists of two critical events: the lock event on the source layer and the release event triggered by our relayer system on the destination.
This interaction is done on the L2Vault contract, with the lock happening using the *depositERC20* method, while for the asset release, the *withdrawTo* method is called on the L2Vault contract deployed on the other side.

In terms of the necessary liquidity for these actions to happen, users deposit liquidity using the VaultL1 smart contract deployed on the L1 mainnet.
Users obtain rewards in the form of LAYR tokens in exchange for providing liquidity.
L1 Vault acts as master with regards to the L2 vaults and redistributes the liquidity on demand.

By leveraging a lock/unlock pattern in Mosaic's Phase I, we prove that we can obtain interoperability in the DeFi space. A single curated interface is enough for the user to operate on different layers and chains.
We also obtained data about the user experience and liquidity demands on different networks.
Nevertheless, we kept the functionality limited for testing purposes.
Thus, we dedicate the next phase to enhancing and opening the protocol to more complex features.

## 6.2 Phase II {#sec:phase-ii}
Phase II represents the evolution of Mosaic v1, our proof of concept.
Phase II introduces two main components: a new active/passive liquidity model and a new and more complete set of features that deeply extend the functionality of Mosaic. Phase 2 allows using different tokens on the source and destination layers and introduces the support for new chains such as Moonriver, Fantom, and Avalanche.

### 6.2.1 Active and passive liquidity
In Mosaic v2 the user can provide liquidity on any layer and in exchange, besides the APY, he receives receipt tokens that can be integrated with other protocols (e.g: use them as collateral for loans).
The user is also able to withdraw liquidity at any point he desires, our dynamic withdrawal fee will calculate the proportional rewards and the user will be credited with the right amount of tokens.
Liquidity can be also directly provided using ETH, and ETH can be transferred among the different layers. In addition to all these new possibilities, we introduce two types of liquidity for different profiles:

* **Passive liquidity:** In this type of liquidity-providing, a more conservative user can obtain rewards by providing liquidity in his desired layer. It can be understood as staking assets to yield some farm.  On the withdrawal, the user gets the rewards and recovers the initial liquidity. Passive liquidity can only be withdrawn in the same token it was deposited. 
        
* **Active liquidity:** This liquidity providing model is intended for more knowledgeable and active users with an elevated risk appetite. By leveraging Composable SDK, they can run a dedicated bot to monitor the mempool and the liquidity requirements of the transactions. If the liquidity of the destination layer is not enough, users can front-run those transactions to gain greater rewards. Active liquidity is specified in the number of blocks and automatically becomes passive liquidity after that time. Active liquidity requires flow management but allows users to benefit from unbalanced networks to gain additional yield. Active liquidity can also be withdrawn in any token from any network.


### 6.2.2 Cross-Layer Function Calls
Mosaic v2 not only supports value transfers but also offers cross-layer function calls.
The relayer can transfer the function call and its associated parameters from source to destination in a similar manner as value transfers.
To handle calls and returns, it employs a *MsgSender* contract on the source layer, which is in charge of abstracting the user and communicating with the relayer, and a *MsgReceiverFactory* contract on the destination layer.
*MsgReceiverFactory* creates *MsgReceiver* instances, which create a virtual identification of the user on the destination network, and interact with the desired protocol.
All the interactions on the destination layer are done through the factory contract.

This general architecture, as shown on [@fig:crosscall], allows users to call any protocol on any network and from any source.
This elevates Mosaic v2 to a new level of unification, not only value is transferred, but also functionality is bridged together.

![Cross-layer function call architecture.](images/mosaic/crosscalls.png){#fig:crosscall}

### 6.2.3 Other improvements
In addition to the improvements already mentioned, phase II of the protocol presents the following and varied advances:

* Transfer NFTs (ERC-721) between networks by using Ethereum research wrapper proposal [@WhyPropertiesb].
* More secure and controlled vaults. Instead of a single *MosaicVault*, everything is isolated in different and dedicated *MosaicHoldings* smart contracts.
* Real-time liquidity balancing. See [@sec:liquidity-reb-sys] for more details.
* More efficient management of unused funds. Single or combined assets can be used to yield-farm, resulting in better and more competitive APY for Mosaic's liquidity providers.

## 6.3 Phase III {#sec:phase-iii}
Phase I was about proving a concept and demonstrating that a less fragmented DeFi space as possible.
Phase II was about enhancing and increasing the features of Mosaic as well as adding new liquidity models.
Phase III is focused on increasing the decentralization of our solution.

Mosaic’s core consists of a network of bridges, operated by relayers interacting with smart contracts on source and destination chain.
Phase I and II are based on a trusted relayer solution, that monitors all connected chains for events, and enacts the transfers accordingly.
Phase III improves on this model by decentralizing the relayer, using different cutting-edge technologies such as Threshold-Signature-Scheme (TSS).
We allow users to directly participate and monitor Mosaic's core functionality.

#### RelayerSet
Each one of the bridges that constitutes Mosaic will be maintained by a group of decentralized and distributed relayers.
This set of relayers will manage accounts and smart contracts on both the source and the destination chain.
RelayerSets may form a multi-signature account, or use TSS to collectively manage a single private key.
The relayers monitor the source chains for XCT requests and based on the parameters and funds transferred, create the appropriate transactions on the destination chain.

#### RelayerSet Creation
We’ve chosen to use RelayerSets instead of single relayer nodes to reduce the chance of fraudulent relayers, as well as reduce the stake required to participate as a relayer.
To increase the security of the RelayerSets, and decrease the risk of a Sybil attack, we assign relayers at random to different RelayerSets on-chain.

A user who wants to form part of a relayer group of a given size sends a transaction and initiates the registration.
The transaction includes the identification of the user, the stake she is providing, and the size of the TSS she would like to form part of.
The algorithm shown in [@fig:algtss] contains the pseudo-code of the joining process.

![TSS group generation Algorithm.](images/mosaic/phase3/alg-01.png){#fig:algtss}

#### Staking and Slashing
In any form of a distributed system in which free actors can take part, there is an open door to malicious and/or selfish behavior.
Because every randomly-generated imaginary entity likes money [@LightningNetwork], we need to provide our protocol with a mechanism that punishes malicious actors, while at the same time incentivizing and rewarding honest behavior.

A stake amount is required to form a RelayerSet, and to individual relayers to join an already established set.
The total stake by a RelayerSet sets the budget for their disputable transactions.
For a RelayerSet to commit fraud, more than threshold relayers need to commit fraud.
For security reasons, we may require an elevated percentage of the relayers within a set to contribute to creating a transaction.

Both TSS and multi-signatures can be used to construct fraud-proofs showing which specific relayers colluded, which then leads to a slash of funds on the source chain side.
Verification of these fraud-proofs is very efficient, as we do not need to prove that a fraudulent transaction was included in the destination chain, only that the relayers signed a fraudulent transaction.

Transactions may be disputed by validators for a certain amount of blocks, we refer to this as the dispute window.
As the protocol has Alice submit the transactions for the XCT, both the RelayerSet and Alice need to collude to commit fraud, making the total $slashable_{amount} = funds_{transferred} + relayer_{stake}$.
This means that the $funds_{transferred}$ on the destination chain need to remain locked for the duration of the dispute window.

Although $slashable_{amount}$ cannot effectively be reduced; we can unlock the user’s funds earlier, by having liquidity providers stake the $funds_{transferred}$ portion of the slashable amount.
An insurer node operates similarly to a validator (it serves both roles) and observes valid XCTs.
The XCT specifies that it wishes a faster unlock on the destination side, and the total fee it is willing to pay for the underlying stake.
An insurer node may then choose to provide the stake for the specified fee.
As the insurer node can observe the mempool, source chain, and destination chain state, it can determine finality and take the risk that the smart contract cannot.
Thus, we provide a faster unlock method to the final user and an opportunity for experienced validators with greater risk appetite to gain additional fees.
An insurer node might be prohibitively expensive for individual users to run.
We will provide some way to allow users to provide their assets to a pool, without significant risk.

### 6.3.1 Protocol
We devote this section to giving a general overview of how the protocol of Mosaic v3 will operate and how the new RelayerSets integrate onto the ecosystem.
We also introduce the most common procedures to raise and audit a disagreement during the dispute window.

Let Alice be a user who wishes to transfer an asset from chain Source to chain Destination through a chosen RelayerSet.
This cross-chain transfer (XCT) consists of two smart contract interactions; the first on the source chain, which locks assets (XCT-lock), and the second which unlocks funds on the destination layer (XCT-unlock).

Alice initiates the transaction on the source chain, locking the funds in a time-locked contract and storing the parameters of the proposed transaction,  then confirms it will relay the transaction by interacting with the contract, which permanently locks the funds.
(The confirmation can be negotiated and signed off-chain to reduce gas fees for the relayer).

After XCT-lock has been confirmed, the RelayerSet sends Alice the XCT-unlock transaction, which she commits on the destination chain.
The [@fig:protocol] illustrates the complete process.

![Time interaction scheme of the different actors for a XCT using RelayerSets.](images/mosaic/phase3/protocol.png){#fig:protocol}

#### Disputes
A malicious RelayerSet can commit fraud in several ways, which are handled through on-chain disputes and settled by slashing the stake of the relayers.

  * **Case 1. RelayerSet and user submit an XCT-unlock with no corresponding XCT-lock on the source chain.**
  As illustrated in [@fig:dispute1], when a validator observes a fraud on the destination chain, he must dispute the RelayerSet on the source and destination chain. Disputes on the source chain are more easily settled since the validator only needs to submit the XCT-unlock event to show the intention of the relayer to commit fraud, independently of the inclusion or finality on the destination chain. 
   
    However, disputes on the destination chain are way more complex since different chains present different finality and consensus models. To address this problem, we resort to different proof-of-non-membership that can immediately settle the dispute. If that is not feasible, the dispute may be resolved through decentralized governance.

  ![Time interaction scheme of the dispute resolution when no XCT-lock event is triggered on source chain.](images/mosaic/phase3/dispute1.png){#fig:dispute1}
   
  * **Case 2. RelayerSet and/or user create a transaction in the destination chain with a different corresponding transaction on the source chain.**
  The solution to this dispute is identical to the previous one, as there will be no corresponding entry for the transaction on the source chain. Nonetheless, this case will be less common, as the amount of funds lost by the user is greater (the stake + the cost of the XCT-lock transaction), while it does not present additional gains with regards to case 1.
  
  * **Case 3. RelayerSet does not create a corresponding transaction on the destination chain.**
  Since the RelayerSet confirms on the source chain that it will relay by signing the XCT proposal, the fraud-proof becomes showing the destination chain that RelayerSet committed to signing an XCT-unlock. The user can then re-obtain their funds on the destination chain. The proof is depicted in [@fig:dispute3].

  ![Time interaction scheme of the dispute resolution when no transaction is created on the destination chain.](images/mosaic/phase3/dispute3.png){#fig:dispute3}

In the case where an honest RelayerSet provides XCT-unlock, but the user does not submit the transaction, the RelayerSet may still submit the XCT-unlock transaction during the dispute window and slash funds from the XCT.
Not all destination chains may support smart contracts.
In that case; it must be possible to construct a proof of (non)-inclusion for the destination chain.
The user then re-obtains their funds on the source chain.


### 6.3.2 TSS vs. Multi-signatures
In a decentralized and distributed environment, we need a mechanism that allows for verification, integrity, and non-repudiability of messages.
The most common tool for this goal is the use of digital signatures.
Digital signatures are an instrument of public key cryptography [@Diffie1976NewCryptography] that allows for public verification.
Multiple signatures schemes exist, most of them are based on the initial standard of DSA [@DSSStandard] and can be summarized as the following set of algorithms:

* Key generation$(1^{\lambda}) \rightarrow (sk,pk)$. As the algorithm that takes as input a security parameter $\lambda$ and produces the signing key $sk$ and the public verification key $pk$.

* Signature$(m, sk) \rightarrow \sigma$. Which is the algorithm that takes a message $m$ and the signing key $sk$ to produce a signature $\sigma$.
    
* Verification$(pk,\sigma, m) \rightarrow 1/0$. As the verification algorithm that takes the message $m$ and the signature $\sigma$ and verifies them using the public key $pk$. It outputs a boolean with the result of the verification.

For our cross-chain solution, we consider two well-known and established schemes: multi-signatures and TSS.
Both schemes serve our purpose of redistributing the responsibility among a set of parties, but there are some key differences we summarize here.

* **Multi-signature:** As the name implies, it is a scheme that involves multiple signatures. To be considered valid, different parties need to sign the same content. It can be architectured in a threshold manner such that a minimum of signatures is required to be considered valid (e.g: 2-out-of-3). It produces as many signatures as the set of parties involved.

* **TSS:** Threshold Signature Schemes [@Gennaro2019FastSetup], [@Canetti2021UCAbortsb], are a special kind of signatures that allow redistributing the responsibility between a set of parties. In a TSS, the secret key is not known by any party, each party has a partial secret key, and needs to collaborate with a minimum subset of the parties (e.g: 3-out-of-5) to produce a valid signature. Only one single signature is produced and there is no difference in the signature produced or the verification process when compared to traditional signatures.

Both approaches have their benefits and drawbacks.
On the one hand, multi-signature is easier to implement since it is based on independent signatures and requires no additional setup.
However, it produces multiple signatures, increasing the costs on the blockchain and the verification times, since each signature needs to be separately verified.

On the other hand, TSS requires quite a complicated setup, with multiple sub-protocols and the use of homomorphic cryptography [@Moore2014PracticalSurvey].
Nonetheless, the verification is simpler and faster than the multi-signature scheme.
A simple scheme of both signatures protocols is depicted in [@fig:signatures].

![Multi-signature vs. TSS. Here, $\sigma$ represents a partial or complete signature, $R$ is the randomness used in the process, $M$ represents the message to be signed and $sk_i$ illustrates their partial or personal secret key.](images/mosaic/phase3/signatures.png){#fig:signatures}

Since we are focused and interested in keeping the operational costs as low as possible for the user, we choose the TSS scheme.
The setup can be performed off-chain, and then only a single signature and public verification key need to be broadcast.
This keeps the blockchain transaction and storage costs to a minimum while leveraging and state-of-the-art signature scheme with all the desired security properties.

### 6.3.3 Alternative model
We presented the protocol, the dispute resolution engine, and the cryptographic constructs that enable Mosaic v3.
However, there exists an alternative model we have also considered.
From the data we gather from Phase II, we might consider this secondary approach.
For the sake of completeness, we briefly describe the second model we considered.

As other projects have explored [@HopRollups], [@MOVRMOVR], when a common layer or chain is available (e.g: L1 on Ethereum and RelayChain on Polkadot), cross-chain transfers can be achieved by bundling different transactions.
The state (e.g: transactions or messages) from a source chain is transferred to the destination chain in a cryptographic accumulator, usually in the form of a Merkle Root [@Becker2008MerkleCryptanalysis].
As depicted in [@fig:accumulator], the state is comprised of the source chain and sent to the destination chain through the common layer.
Later on, by proving membership and unpacking the Merkle root, messages can be recovered on the destination layer.
By bundling information, we can reduce transaction costs on the common layer as well as benefit from its security since the whole process is done on-chain.
To ensure the validity of data being transferred, some stake is locked or an optimistic approach is pursued until the source chain settles its states on the common chain.
Then, the data is considered final and can be used as ground truth.

![Accumulator and transfer scheme. Only the Merkle root is transferred on-chain to reduce costs.](images/mosaic/phase3/accumulator.png){#fig:accumulator}

We believe Mosaic is more general than this approach since it does not depend on the existence of a common layer and replaces the finality gadget with a set of decentralized relayers.
Nonetheless, we might consider this agglutination scheme for scenarios in which a common layer can be easily found, to keep as much of the process on-chain.
Please note that this approach still requires, to a certain degree, off-chain services to operate properly.

## 6.4 Liquidity Simulation Environment {#sec:liquidity-sim-env}
As part of building Mosaic [@MosaicFinance] we wanted to understand the nature of liquidity and how its allocation and movement mean for the design of the system.
To that end, Composable Labs [@IntroducingMedium] built a Liquidity Simulation Environment (LSE) [@IntroducingMediumb].

This software tool can simulate allocations of assets to vaults and assets moving around in the network.
It is modular and you can produce data in any form you want.
Currently, the LSE supports data generated from a truncated Gaussian, Geometric Brownian Motion (GBM), and data sampled from our 2021 September-October PoC run [@TestingMedium].

The strategy layer allows for any liquidity allocation and movement approach to be defined.
For example "move liquidity from vault X to vault Y when conditions Z is true".
An objective - which can also be defined in the LSE - useful for searching for the best strategy could be to optimize the liquidity distribution among the vaults so that any transfer can be supported.

Fee models, how much and simply how, to charge moving assets can be defined as well.
We used the PoC in conjunction with the LSE to decide the best fee model to use in the context of available data up to that point.

The LSE is built as a state-machine iterating through the simulated transfers changing the states of the vaults.
Replenishment events can be triggered - for example the Arbitrum vault needs liquidity from the Mainnet vault.

The LSE is also continuously improving.
As more transfer data is received this gives us a unique insight into how Mosaic is used and the LSE can help fine-tune our network to achieve an optimal user experience by having maximum availability.

### 6.4.1 Simulating Data
The LSE supports generating simulated transfer/usage data.
We use this to model the behavior of network usage and based on that make decisions on how to distribute liquidity.

We support generating data from a truncated Gaussian distribution.
We sample a timeline and on that, a set of hypothetical cross-chain cross-layer moves from this distribution with a given mean and standard deviation.
We also support generating data from a Geometric Brownian Motion.
The moves or transactions $N_t$ (amount of \$) from one vault to another, at time $t$, following a GBM model, are described by the following stochastic differential equation (SDE)

\begin{equation}
\frac{d N_t}{dt} = \mu N_t + \sigma N_t\frac{dW_t}{dt},
\end{equation}

with $\mu$ being a drift term, $\sigma$ the volatility, both assumed to be constants and $W_t$ is a Brownian motion stochastic process.
The analytical solution of the above SDE at time t, given initial condition $N_0$, is known to be


$$N_t = N_0 \exp\left[ \left(\mu - \frac{\sigma^2}{2}\right) t + \sigma W_t\right]$$ {#eq:gbmsolution}

which by definition is always strictly positive.
A key property of the solution, important for our LSE use, is that the solution asymptotically goes to infinity when $\mu > \frac{1}{2}\sigma^2$, it goes to $0$ when $\mu < \frac{1}{2}$ and it fluctuates between zero and arbitrarily large values when $\mu = \frac{1}{2}\sigma^2$, therefore for most of our cases we will be using $\mu = \frac{1}{2}\sigma^2$.
As [@fig:gbm] shows two random simulation of [@eq:gbmsolution] for the $N_0 = \$2000$, $\sigma=2$ and $N_0=\$1500$, $\sigma=1$ respectively.
Note that the same initial and volatility values have also been used in our simulations below to simulate moves from Polygon to Arbitrum vaults and vice versa.

![Simulation of Geometric Brownian motion data in Composable's Liquidity Simulation Environment (LSE).](images/gbms.png){#fig:gbm}

These results guided us to an answer to two key questions to kick off the Mosaic PoC: First, how much liquidity should be assigned in total, and then how much should be assigned to each network? Second, which transfer fee model should we initially use?

These results guided us to decide on a good initial fee model to use for the Mosaic PoC.
We then ran the PoC with that model, collected the data, and optimized the model to its final form.
More on that in [@sec:mosaic-fees].

### 6.4.2 Mosaic Fee Model {#sec:mosaic-fees}
One of the first use-cases of the LSE was deciding which fee model to use for Mosaic.
Fees are charged when funds are moved between networks. The question of which fee model to go with is key to a successful deployment.

First, guided by Occam's razor [@WhatRazor] we picked a simple functional form and let the fee model follow a linear form capped by a maximum fee ensuring that nobody, no matter how much they move across Mosaic, is charged more than a certain percent.

For most transfers, and for practically all retail transfers, users move along the linear part close to the origin.
To ensure a safe network, we implemented a minimum fee as well as distributing rewards to maintainers.
Let $x$ denote the liquidity moved as a percent of available liquidity in the origin vault.
For example, if I move 10 ETH in a vault with 200 ETH $x=5$\%.
Let $y$ be the fee charged in percent.
The Mosaic fee model is then determined by the two points $(x,y)=(0,0.25)$ and $(x,y)=(30,5)$.

The Mosaic PoC was run with this model and based on the data the two points were optimized to balance use and network safety (indirectly via rewards collected from fees).
We have three free parameters in our fee model:

* The liquidity-\% at which the maximum fee kicks in (also called $a$)
* The maximum fee \% to charge
* The minimum fee \% to charge

In the PoC these parameters were: 40\%, 4\%, and 0.25\%, respectively.
For ease, we will denote this parameter set in the format (40, 4, 0.25).

The PoC transfer data is visualized in [@fig:pocdatavis].

![Visualizing the Mosaic PoC bridge transfer data. Each network supported by Mosaic in the PoC is a node and edges represent transfers between the networks. Note that Arbitrum and Polygon were there from the beginning and other networks were added later. Thus, edges are not normalized by time and surely do not imply the "popularity" of a network.](images/mosaic/pocdata.png){#fig:pocdatavis width=60%}

We next visualize the fees charged for the PoC data in [@fig:pocdatafees].
To decide on a good set of parameters, we next compare this to bridges seen in the general cross-ledger community.

![Fee charged vs transfer amounts as a percent of available liquidity in the origin vault. For example, if 10 wETH is transferred from a vault on Arbitrum with 1000 wETH it would show up at $x=10$\%. The y-axis shows the fee charged for the transfer. For the PoC vaults were on the order of \$100-200k at the beginning of the PoC. The exact numbers for each token (which in turn was distributed across multiple networks like Arbitrum and Polygon) are available here: [TVLs for Mosaic](https://mosaic.composable.finance/earn) (accessed November 12, 2021).](images/mosaic/poc_transfer_on_fee_curve.png){#fig:pocdatafees}

We find that some operators charge a fixed 0.5\% for all transfers, higher than the average Mosaic PoC case.
Other operators charge different fees depending on whether you are leaving Ethereum or arriving from another chain.
Some charge a fixed dollar amount and others a percentage with minimum and maximum dollar amounts.

Some operators do not charge a fee but instead charge a "hidden fee" by quoting a given "transfer rate".
They also create bi-directional fees (mainnet to polygon is different than polygon to mainnet).
Other operators charge a fee that is a multiple of the destination network fee.
And so on.

Given this landscape of fees, the following parameters were chosen: (30, 4, 0.25) (liquidity-\% at which max fee kicks in, maximum fee \% to charge, minimum fee \% to charge, respectively).
This optimized fee curve is shown in [@fig:pocdatafeesopt].

![The PoC data transformed to the optimized fee curve with parameters (30, 4, 0.25).](images/mosaic/poc_optimized.png){#fig:pocdatafeesopt}

### 6.4.3 Continuous Improvement {#sec:continuos-imp}
With the LSE we can continuously collect data from the operation of Mosaic and periodically revisit the fee model parameter settings.
This introduces us, as shown, to a pure data-driven approach to determine this.
We would use Graph QL [@GraphQLAPI] to collect data from the Mosaic network, compute the fees/revenues collected and ensure that we stay within a certain band of expected and allowable values.
We make this check once a week.
If we stray away from expected values, we modify the parameters if necessary based on a data review.

## 6.5 Liquidity Rebalancing System {#sec:liquidity-reb-sys}
The best user experience is obtained when the liquidity availability is high thus allowing, in general, any token to be moved from any network to any other network.

To that end, we used the LSE from [@sec:liquidity-sim-env] to design a forecasting and rebalancing technology that can predict in advance when a certain liquidity level will be reached for a given vault.
This is built into Mosaic.
It is critical for the optimization of the passive liquidity rebalancing that will enable passive liquidity providers to continue to service cross-layer transfers.
Having an optimal allocation of capital across layers is key to offering the best performance for users seeking to move cross-layer.
Therefore, understanding when said capital reaches certain key levels where the action will need to be taken is important.

More formally, enter the Liquidity Rebalancing System (LRS) developed by Composable Labs.
In [@fig:lrd] we show a graph of various networks such as the Ethereum mainnet, a layer 2 solution Arbitrum, Avalanche, and Fantom, but Mosaic supports many more networks and is growing.

![Sketch of the Liquidity Rebalancing System showing how a forecast model is built on the liquidity in each vault in the Mosaic network. Transfer of funds are moved as needed when a subset of vaults are depleted (to a certain pre-set level, we use 90\% here which is conservative) needing funds from a donor vault.](images/lrs.png){#fig:lrd width=85%}


LRS builds a forecasting model on each network (shown as the insets with black lines being the liquidity data and green lines being the forecast model).
At a given frequency, e.g. hourly, it checks the status of all networks, computes where liquidity is needed, and performs the transfers.
The transfers take place as follows: if a vault is predicted to be depleted to 80\% of its seed amount then funds are moved from a so-called "donation" vault.
If a vault has too much liquidity, or satisfies a broader set of metrics to be defined later, it becomes a donation vault (this status is temporary).

The system overall consists of two key pieces: First, we have a forecasting model predicting the evolution of liquidity in a single vault on a single network and second, we have a broader logic deciding how to distribute available liquidity across the entire connection of networks (a connected graph).

### 6.5.1 Forecasting a Single Network

To forecast a single network we developed multiple models starting with a set of baseline models including an autoregressive integrated moving average (ARIMA) model [@AnScience], Holt's linear trend model (HLT) [@7.2Ed], and a Holt-Winters seasonal method [@7.3Ed].
We will show the ARIMA and HLT performance in what follows.

Also, the eventual goal is to build Artificial Intelligence (AI) [@ArtificialBritannica] based models such as long short-term memory (LSTM) [@UnderstandingBlog].
This work is in the pipeline and the non-AI baseline models will help us compare and also develop a two-tiered system where non-AI and AI work to forecast together.

#### Forecasting with ARIMA

To simplify the discussion and without loss of generality, we assume a graph of three networks: L1, Arbitrum (ARB), and Polygon (POL).
We first develop an ARIMA model to fit and forecast liquidity data on the POL vault, that can be mathematically described as

\begin{equation}
Y_t - \alpha_1Y_{t-1} - \dots - \alpha_{p'}Y_{t-p'} = \epsilon_t + \theta_1\epsilon_{t-1} + \dots + \theta_q\epsilon_{t-q},
\end{equation}

where $Y_t$ is our time series data at discrete time $t$.
Although the above expression applies to the more widely known \emph{autoregressive moving average} (ARMA) [@TimeScience] models with $p'$ and $q$ being the orders of the autoregressive (AR) and moving average (MA) terms, here we also account for the fact that non-stationary effects are present in our data and, therefore, a differencing step needs to be applied to the data before fitting the model.
The order of the differencing step depends on the multiplicity of the unit root.
Using the lag operator notation, $L^i[Y_t] := Y_{t-i}$, the times series model can be written as

\begin{equation}
\left(1 - \sum_{i=1}^{p'} \alpha_i L^i\right) Y_t = \left(1 + \sum_{i=1}^p\theta_i L^i\right)\epsilon_t
\end{equation}

and in the presence of a unit root with multiplicity $d$ we have

\begin{equation}
\left(1 - \sum_{i=1}^{p} \phi_i L^i\right) (1 - L)^d Y_t = \delta + \left(1 + \sum_{i=1}^p\theta_i L^i\right)\epsilon_t
\end{equation}

representing the ARIMA(p, d, q) process.

Next, we developed an automated model selection of the ARIMA order parameters such that the rebalancing system does not require manual input to determine its parameters when a dataset is provided.
Below we are presenting a list of criteria that we have used to identify the optimal order of differencing $d$ in the data and the orders of autoregressive and moving average terms, $p$ and $q$, in the ARIMA(p, d, q) model.

#### Identifying the order of differencing in the data

The first step in fitting an ARIMA model is the determination of the order of differencing needed to "stationarize" the series.
Normally, the correct amount of differencing is the lowest order of differencing that yields a time series that fluctuates around a well-defined mean value and whose autocorrelation function (ACF) plot decays fairly rapidly to zero, either from above or below.
If the series still exhibits a long-term trend or otherwise lacks a tendency to return to its mean value, or if its autocorrelations are positive out to a high number of lags (e.g., 10 or more), then it needs a higher order of differencing.
Although the presence of most of these characteristics can be observed by simply looking at the differenced data plots, to automate our model selection procedure, we work primarily with the autocorrelation function.

The first rule that we apply is that, if the series has positive autocorrelations out to a high number of lags, then we increase the order of differencing by one.
A sign that can often indicate that the time series might be over-differenced is to observe a lag-1 autocorrelation that is below $-0.5$.
In practice, to apply these two rules, we fit an ARIMA(0, d, 0) model, that is a model with no AR or MA terms, but only a constant term which when trained, provides an estimate of the mean of the data.
Thus, the residuals of this model are simply the deviation from the mean.
Once we identify a sufficient $d$ such that the autocorrelation function drops to small values past lag-1, we also compare the resulting model with an ARIMA(0, d+1, 0).
Assuming that lag-1 autocorrelation does not fall below $-0.5$ (which would be a sign of over-differencing), if the model with d+1 order of differencing exhibits lower standard deviation values then it is preferred over $d$, otherwise we keep $d$ and we proceed with the selection of optimal $p$ and $q$ orders.

#### Identifying the AR(p) and MA(q) orders

Next, to identify the number of autoregressive and moving average terms, we proceed as follows:
For the number $p$ of AR terms, we set it equal to the number of lag terms that it takes for the partial autocorrelation function (PACF) to cross the significance limit.
Similarly, the number $q$ of MA terms, we use the autocorrelation function (ACF) instead and it is set again equal to the number of lag terms that it takes to cross the significance limit.

#### Optimizing the ARIMA model for our LSE data

In what follows we employ our model selection capability explained above to optimize our ARIMA model parameters and use them for forecasting.

We generate simulated data with the LSE.
Our time series data consists of $1000$ liquidity transfer observations obtained on an hourly basis ($\Delta t = 1$ hour).
We briefly touched on how these are computed, but let us provide more details here.
We select several token movements of the vaults.
These are drawn from a truncated Gaussian with parameters set to resemble real-world transfers.
As an aside, the Mosaic PoC provided even more realistic data and we have developed ways to account for this as well - we can confirm that our simulated data resembles the PoC data.
Then, the simulated data is snapped to a global time grid and a state machine is used to evolve the vault states forward starting at some initial liquidity levels.
This gives rise to the evolving liquidity levels over time as plotted in [@fig:lse].

![Dataset 1 (top) and Dataset 2 (bottom) from the Liquidity Simulation Environment (LSE). Each vault is a row. The liquidity is shown as the moving curves in rows 2 and 3. Row 1 does not have transfers involved with it for this data.](images/lse_results_feemodel_3_20_20211015_18_59_40_412997.png){#fig:lse}

![](images/lse_results_feemodel_3_20_20211021_18_59_52_314364.png)


We use $200$ training points (roughly 8 days worth of data) each time we fit an ARIMA model and we use it to forecast on a time horizon of $168$ hours; roughly 1 week ahead which coincides with some layer 2 to layer 1 exit times.

Then, we run the model selection algorithm every time we shift the time frame 10 timesteps ahead, and we find that in all cases the number of AR terms varies from $3$ to $6$ while the optimal number of MA terms is always $1$ for both Datasets 1 and 2.

We next show the performance of the ARIMA model as well as of HLT.
In the HLT approach, also known as double exponential smoothing, we identify a linear trend in the time series and make a prediction using the smoothed value $s_t$ and the linear trend term $b_t$ at time $t$.

See the forecasting comparison and performance for the Arbitrum vault in [@fig:arb_conserv].

![Forecasting comparison between ARIMA and HLT models. The black point shows when the ARIMA model predicts that a 90\% liquidity level is reached in the vault - by conservative estimates (the lower confidence level). The purple point shows when the HLT model predicts the same 90\% liquidity level. While both predictions can be used to trigger, in advance, a replenishment event, the ARIMA predictions appear to be much more conservative.](images/arbitrum_instance_t_fin270_90perce_drop.png){#fig:arb_conserv width=95%}

We run a forecasting model on each vault and this, in turn, triggers the rebalancing system to move liquidity accordingly to always keep the vaults ready and liquid thus maximizing the successful transfer rate.

We note that, as we run the forecasting model across the data in a rolling window fashion, the data is contained within the 95\% confidence bands in the amount of time expected allowing us to perform accurate and conservative replenishment event estimates.

### 6.5.2 Rebalancing Logic

With a forecasting model built on each network, the next step is designing the rebalancing logic of the overall system.
Here is our approach.
At a given cadence that can depend on transfer activity in the general network, we check the following: First, what is the set of current liquidity donation vaults.
We assign a score to each vault and sort them. For each donor, we also log how much liquidity can be donated.
This implies that we have a list of candidate liquidity donors.
Next, we obtain the list of vaults which need liquidity.
Perhaps this is an empty set, but assuming not, we simply deplete as much liquidity from the donors going top-down until all liquidity has been rebalanced.

The score assigned to a vault in the "donor detection phase" is determined based on a set of metrics including: how active is this vault (inactive implies that it can donate without needing liquidity itself), how much "active" liquidity is assigned vs passive, what value the forecasting model predicts it will take in the future (is it generally increasing or decreasing in liquidity), and many more.

# 7. Centauri and Expanding the IBC {#sec:centauri}
Composable is working on expanding the [Inter-Blockchain Communication (IBC) Protocol](https://ibcprotocol.org/) to become the primary digital asset transport layer across different chains.
The IBC Protocol allows for the trustless passing of arbitrary data in opaque packets between [Cosmos Software Development Kit (SDK)](https://v1.cosmos.network/sdk) chains.
This trustlessness is achieved through light clients and finality proofs, rather than relying on the conventional relayer and mint structure.
We are connecting the IBC Protocol to chains in other ecosystems that support light clients by integrating light clients that track the finality in these ecosystems on IBC.
This becomes the transport layer for the Composable XCVM, facilitating cross-layer movement of information and assets.

Centauri will be the first bridge created by Composable to accomplish this goal.
Centauri is a trustless, final bridge between [Picasso](https://www.picasso.xyz/) (Composable’s parachain on [Kusama](https://kusama.network/)) and the [Cosmos](https://cosmos.network/) ecosystem.
In contrast to [Mosaic](https://mosaic.composable.finance/), Centauri serves to bridge Picasso to blockchains and layers that have light clients installed.
Through Centauri, the Composable Ecosystem (and the broader DotSama ecosystem) are bridged to all projects connected to the IBC Protocol and Cosmos.
This positions Centauri to be the first-ever bridge between the DotSama and Cosmos ecosystems.

As mentioned, we will additionally create other bridges using the IBC to connect Polkadot (and the Composable Ecosystem) to more blockchains, such as [NEAR](https://near.org/).
Combined, Mosaic, Centauri, and additional bridge expansions of the IBC from Composable aim to connect all chains in DeFi to the Composable ecosystem.

The key challenge in executing upon the goals of Centauri is to reach consensus on the finality of the two networks it is connecting in a trustless manner, which guarantees the correctness and security of cross-chain bridging.
This is achieved with several pieces of new technology.
Firstly, the light clients allow nodes to verify the blockchain state without downloading the full block data, thus ensuring light computing requirements and decentralization.
Secondly, Merkle Mountain Ranges (MMRs) allow new block headers to be hashed in an ‘append-only’ manner, which is more suited for use in consensus subsystems other than Merkle trees.
Finally, the BEEFY finality gadget makes use of Merkle Mountain Ranges to produce finality proofs for parachains in a more efficient way. These components are shown below:

![Centauri Overview](images/centauri/centauri_progress.png)

The Composable team is currently contributing to the core BEEFY systems as well as reviewing an IBC Light Client for Cosmos.
Once merged with IBC upon further audits, this will allow Cosmos chains to directly communicate with Substrate chains on Dotsama.

To create the proof of concept (PoC) of Centauri, we are working with [Osmosis](https://osmosis.zone/), an automated market maker (AMM) in the Cosmos ecosystem.
Then, we will hold a larger scale launch of the bridge, serving as a DotSama-IBC Substrate bridge to power enhanced interoperability in DeFi.

## 7.1 Light Clients {#sec:lightclients}
Highly efficient light client protocols are crucial in enabling the decentralization and mainstream adoption of blockchain protocols.
Light clients are also what make bridges on the IBC possible; the IBC Protocol bridges to other chains by having light clients on either side of the connection.
These light clients facilitate the passing of IBC opaque packets of information (i.e. transactions and associated information).
Since Centauri uses the IBC Protocol, it also leverages these light clients to facilitate connections, even further expanding upon the bridging opportunities of the IBC itself.

Light clients provide environments with computation and memory resource constraints (e.g. mobile, on-chain contracts) with the ability to verify the latest blockchain state without the need to execute and store the full block data and state.
Light clients instead track block headers as opposed to tracking the full blocks and executing transactions to arrive at the latest state.
It is important to note that blocks are simply composed of the header and transactions:

![Block Structure](images/centauri/headers.png)

The size of the transactions in a block might vary, but headers have a fixed size (usually no more than 1kb) and contain the following:

![Header Structture](images/centauri/header_structure.png)

Light client protocols consist of a combination of transaction Merkle proofs, state proofs, consensus proofs, and finality proofs, which are all usually included in the block headers with the exception of finality proofs.
This is because finality proofs may differ from the consensus proof and require data that is an extension of the header.

### 7.1.1 Transaction Root
This is the Merkle root of all transactions that have been executed in this block.
This Merkle root can be seen as a kind of cryptographic compression that allow trustless verification in the event that some data was part of the original data that was compressed by a Merkle proof, illustrated below:

![Merkle Transaction Root](images/centauri/merkle_root.png)

The Merkle proof required to check if some element was included in the root would be log2(n) hashes, which are usually 32 bytes.
In the diagram above, we only need 4 hashes (outlined in blue) to prove or otherwise reconstruct the original root hash that K was indeed part of the original Merkle tree.
The math is $n = 16, \log_2(16) = 4$.
This enables light clients to efficiently check which transactions were executed in a block without needing to download the full block that may potentially contain thousands of transactions and having to scan this list linearly.

### 7.1.2 State Root
The state root of a blockchain is similar to the transactions root in that it is the output of the cryptographic compression of data.
However, where the transaction root is a compression of a list of transaction data, the state root can be seen as the compression of a list of keys and values.
Take, for example, the Ethereum state tree architecture:

![State Root](images/centauri/state_root.png)

Hence, the keys and values are the data stored on the blockchain by contracts or core blockchain subsystems, like the consensus protocol storing the list of authorities and their stakes.
By compressing this data into a kind of Merkle root, it is possible to check the existence of some key value against the root hash and a Merkle proof without needing to maintain the full blockchain state, but still having the same trussless guarantees as a full node.

### 7.1.3 Consensus Proofs
The consensus proof that a block is valid is usually included in its header and its format is entirely dependent on the consensus protocol of the blockchain.
For proof-of-work (PoW) systems, the consensus proof is a nonce that satisfies the equation:

![State Root](images/centauri/pow.png)

As seen above, finding a value that satisfies this equation would require a significant amount of computation as the hash functions cannot be brute-forced, but verifying this consensus proof is relatively inexpensive and fast.
Meanwhile, the consensus proof for a proof-of-stake (PoS) protocol is usually the output of a verifiable random function where:

![State Root](images/centauri/pos.png)

Most blockchain protocols’ consensus mechanisms usually only guarantee liveness, hence verifying these consensus proofs only tells if this block is valid.
It does not, however, tell if this block should be considered as final.
In the case of PoS, blocks that are not signed by a public key in the known authority set are not considered to be valid.
Consensus proofs provide trust guarantees about a block to the nodes on the network pending finalization, as competing blocks for the same block height may arise in a byzantine system.
It is entirely up to the finalization protocol to provide safety guarantees.

### 7.1.4 Finality Proofs
For light clients to verify that events are happening on chain, they need a finality proof.
This is cryptographic proof that the transactions in a block are final and that the block can never be reverted.
These proofs could be part of the headers or could be requested alongside the header from full nodes.

For proof-of-work blockchains, this finality proof is actually embedded in the headers as the proof-of-work nonce.
However, this alone is not enough to guarantee finality.
Rather, we need a certain threshold of similarly valid headers that reference this header as its parent in order to be truly convinced of its finality.
This vastly increases the storage requirements for light clients that want to be convinced of finality, since they must store n headers to verify the finality of n-1 headers.

Even then, the finality is entirely probabilistic and dependent on the security of the hash functions used in deriving the proof-of-work nonce.

For proof-of-stake blockchains, the finality proof is usually not included in the header but is optionally available to light clients to request alongside the headers.
The finality proof will typically consist of the signatures of the known authority set, who have staked their tokens on the network and sign what they think is the latest block in the network.
The finality proofs in this system are signatures of this data from $\frac{2}{3} + 1$ of the known authority set, under security assumptions that less than a third of the authority set is malicious.

### 7.1.5 Ancestry Proofs
Unfortunately, most finality proofs require light clients to be aware of the full chain of headers that have been finalized in order to follow the finality protocol.
To enable trustless bridging between two networks via light clients which run in smart contract environments and have even stringent computation and memory constraints, Composable needs smaller-sized ancestry proofs which do not require awareness of every header in the blockchain.

This could be attempted using Merkle trees, where a light client simply tracks the Merkle root of all block headers seen so far.
Merkle proofs could then prove finality about any header to a light client that only knows the Merkle root of all finalized blocks.
However, because of the structure of Merkle trees, this would require recalculating the full tree structure from the genesis block all the way to the latest block, for every new block.

Thus, 2,097,151 nodes would need to be recalculated for every new block for blockchain that already has a million blocks:

> Tree height = $log₂(1,000,000)$ // a million blocks
> 
> Tree height = 20
> 
> Nodes in the tree = $2^{20 + 1} — 1$
> 
> Nodes in the tree = 2,097,151

To prevent this staggering amount of work, Composable needs a tree structure that preserves the $\log_2(n)$ proof sizes of a Merkle tree but also re-uses in some way the previous hash computations on older nodes in the tree whenever new data is added to the tree.

## 7.2 Merkle Mountain Ranges {#sec:mmr}
Merkle Mountain Range trees resolve this high computational volume problem by enabling highly efficient ancestry proofs.
Merkle Mountain Ranges (MMRs) are a special kind of Merkle tree that is composed of perfectly-sized binary subtrees in descending order of height.
For example, an MMR tree with 1,000,000 leaves will be composed of 8 perfect subtrees of heights: 19, 18, 17, 16, 14, 9 and 6:

![Scheme of a Merkle Mountain Range](images/centauri/mmr.png)

A key feature of MMR is the reuse of the previous computations (root hashes) whenever new leaves are added to the tree.
The rules for adding new leaves to an existing MMR tree require merging any two subtrees of the same height (i.e. the pink section and blue section are merged to the hash in blue in the following two images), so there is only ever one subtree per height level:

![State before adding leaves](images/centauri/mmr_1.png)

![State after adding leaves](images/centauri/mmr_2.png)

Merkle Mountain Ranges are also very efficient with proofs where the tree itself is composed of subtrees.
Since MMR subtrees are presented in descending height, the first subtree is typically the heaviest to compute.
This also means that, as the list grows, new leaves are actually less expensive to insert and prove.

![State after adding 2 more leaves](images/centauri/mmr_3.png)

In the continued example of the above tree, the subtree that requires the most proof items is the first subtree, 4 + 2 (peak nodes of the other 2 subtrees) = 6 proof nodes.
The benefit of the MMR is that, when adding new leaves, there is no need to recalculate the hashes of the first subtree, only the more recent ones:

![Proofs for MMR](images/centauri/mmr_4.png)

## 7.3 The BEEFY Finality Gadget and 11-BEEFY COSMOS-IBC Light Client {#sec:beefy}
The final pieces of technology contributing to the construction of Centauri leverage Parity’s Bridge Efficiency Enabling Finality Yielder (BEEFY) and its novel consensus gadget that enables DotSama to be bridged to additional chains via very efficient finality proofs.
Parachains get their finality from the Kusama relay chain, and thus BEEFY’s ability to create finality proofs provides finality for Centauri on Picasso and an essential gateway for the bridge infrastructure.

We are also developing a BEEFY light client implementation for Cosmos-IBC (11-BEEFY, spec pending). This product will enable Cosmos chains to follow the finality of the Kusama relay chain (and thus, the finality of Picasso).
A single instance of this light client on any Cosmos chain can prove finality for any Kusama parachain, allowing Cosmos chains to verify IBC commitment packets (IBC consensus proofs). The final piece of Centauri is a pallet on Picasso, facilitating the creation of these IBC commitment packets.

### 7.3.1 BEEFY Finality Gadget {#sec:gadget}
With the BEEFY protocol, the authority set produces an extra finality proof for light clients which consists of the MMR root hash of all blocks finalized by GRANDPA (the finality gadget implemented for the Polkadot relay chain) at a given height.
With the introduction of this protocol, light clients no longer need to be aware of all the headers in a chain for them to be convinced about finality.
This drastically reduces the size of the data that light clients must store to follow the chain’s consensus to exactly 124 bytes.

A preliminary specification for BEEFY is already available and is largely implemented, barring a few kinks that need ironing out.
At a high level, this is a new protocol that will be added to Polkadot without the need for a hard fork.
Thanks to the WebAssembly (Wasm) runtime and the on-chain governance protocol, this new protocol will produce significantly lighter finality proofs for light clients for both on-chain and off-chain uses.
It will achieve this by having the existing GRANDPA authority set periodically vote on the Merkle Mountain Range root hash of all blocks that have been considered final by the network.
This proof is shown below:

    pub struct BEEFYNextAuthoritySet {
      /// Id of the next set.
      ///
      /// Id is required to correlate BEEFY signed commitments with the validator set.
      /// Light Client can easily verify that the commitment witness it is getting is
      /// produced by the latest validator set.
      pub id: u64, // 8bytes
      /// Number of validators in the set.
      ///
      /// Some BEEFY Light Clients may use an interactive protocol to verify only subset
      /// of signatures. We put set length here, so that these clients can verify the minimal
      /// number of required signatures.
      pub len: u32, // 4bytes
      /// Merkle Root Hash build from BEEFY AuthorityIds.
      ///
      /// This is used by Light Clients to confirm that the commitments are signed by the correct
      /// validator set. Light Clients using interactive protocol, might verify only subset of
      /// signatures, hence don't require the full list here (will receive inclusion proofs).
      pub root: H256, // 32 bytes
    }
    
    
    // Data that light clients need to follow relay chain consensus
    pub struct BEEFYLightClient {
      pub latest_BEEFY_height: u32, // 4bytes
      pub mmr_root_hash: H256, // 32bytes
      pub current_authorities: BEEFYNextAuthoritySet<H256>, // 44bytes
      pub next_authorities: BEEFYNextAuthoritySet<H256>, // 44bytes
    }

Composable is performing a total of [8 PRs to core BEEFY subsystems](https://github.com/paritytech/substrate/pulls/wizdave97) in both the runtime and Substrate client, pending further review by the Substrate bridges team.
Some are listed below:

- [1](https://github.com/paritytech/substrate/pull/10669): Introduces a runtime API to the BEEFY finalization gadget for fetching the block number where the current session began.
- [2](https://github.com/paritytech/substrate/pull/10727): Implements an algorithm for deterministic block selection for finalization by the BEEFY gadget.
- [3](https://github.com/paritytech/substrate/pull/10705): Prevents the finalization gadget from starting while block syncing is still in progress.
- [4](https://github.com/paritytech/substrate/pull/10684): De-duplicates BEEFY finalization notifications sent to RPC subscribers.
- [5](https://github.com/paritytech/substrate/pull/10664): Refactors the runtime subsystems for BEEFY to be generic for downstream runtimes, e.g. parachains.
- [6](https://github.com/paritytech/substrate/pull/10635): Introduces support for generating multi-leaf MMR proofs for even smaller finality proofs.

### 7.3.2 11-BEEFY COSMOS-IBC Light Client {#sec:beefyIbc}
Connecting to IBC requires both chains (in the case of Centauri, Cosmos and Picasso) to embed a light client for proof of validation.
In order to connect to IBC using Cosmos and Picasso, Composable is working to develop a Bridge Efficiency Enabling Finality Yielder (BEEFY) light client onto Picasso and Cosmos.
In this process, Composable is working closely with [Strangelove](https://www.strangelove.ventures/), an early-stage venture fund focused on supporting DeFi protocols in the broader IBC ecosystem.
Strangelove already has an IBC implementation layer in the [Go](https://go.dev/) programming language.

To support Substrate-based chains on the Cosmos side, Composable will need a BEEFY-IBC client merged into IBC-Go; therefore, the first step in the process is to create a BEEFY-Go followed by a BEEFY-IBC.
Once this is set, Composable will work on updating the relayer before launching the product.

Composable has completed the development of this [BEEFY light client](https://github.com/ComposableFi/ibc-go/blob/main/modules/light-clients/11-beefy/README.md) in Go for the Cosmos ecosystem, with the product being called the 11-BEEFY COSMOS-IBC light client.
Pending further audits, this light client will be merged upstream into the IBC-Go repo which hosts the canonical implementation of the [Tendermint](https://tendermint.com/) light client.

Composable’s intent is that this light client will serve as the canonical light client for Cosmos chains to communicate directly with DotSama parachains.
A single instance of the light client can track either the Kusama or Polkadot relay chain’s finality and be used to prove the finality of any of the connected parachains’ states.
In the spirit of trustlessness, Composable has published a demo with [instructions](https://github.com/ComposableFi/ibc-go/blob/main/modules/light-clients/11-beefy/README.md) for everyone to run a test to verify the operation of the light client. The draft spec is available [here](https://github.com/ComposableFi/ibc-go/blob/main/modules/light-clients/11-beefy/spec.md).

Our plan is to use [Osmosis](https://osmosis.zone/), the Automated Market Maker (AMM) of Cosmos, and Picasso to run our proof of concept (PoC) before moving onto a larger-scale launch.
Ultimately, this BEEFY implementation will set the stage for a DotSama-IBC Substrate bridge allowing for seamless cross-chain communication and asset transfers between the Cosmos and Composable ecosystems.

In time, we will also create another Substrate bridge to connect Mosaic to our Picasso-IBC bridge.
This will allow us to generalize the asset transferal system to extend across more ecosystems and better serve its role as a hyper-liquidity system.

The BEEFY light client is a step towards building out the Centauri bridge which connects DotSama and Cosmos.
Composable has completed the development of the BEEFY light client to be merged on the Cosmos side (pending reviews), and the other two components are in development.


# 8. Conclusion {#sec:conclusion}
Composable is on a mission to unlock the interconnected ecosystem of blockchains via a cross-chain, cross-layer networking fabric.
Moving assets intra-ecosystem is becoming more intuitive.
However, more and more applications have begun to shard operations across one or several blockchain L1 and L2 networks to minimize costs and maximize performance the implications being asset transfers and smart contract executions that are increasingly more complex and ambiguous.
We are approaching a world in which the future of DeFi will be fully blockchain-agnostic.
Like Port Control Protocol of the Internet, Composable's mission is to service all these interactions, transfers, and communications cross-ecosystem.

Both developers and users will seek ways to interface with multiple ecosystems in a user-friendly, scalable, provable, and decentralized manner.
In this construction paper, we discussed our thoughts and designs to provide this future in the form of Virtual Machines, Routing Layers, Finality and Application layers, and we introduced Mosaic the cross-ledger highly competitive transferal system backed by advanced engineering.
All of our technologies are backed by strong guiding principles in both engineering and programming practices.

Composable's full technical stack is driving the evolution of digital assets and DeFi protocols.
It enables the unification of functionality, across all blockchain ecosystems.
We are engineering the fully interoperable future and we embrace the sharded efficient ecosystem which is rapidly expanding.

\pagebreak
# 9. Bibliography
