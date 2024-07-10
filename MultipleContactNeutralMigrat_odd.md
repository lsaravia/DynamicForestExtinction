# ODD

## 1. Purpose and patterns

The purpose of this model is to simulate the dynamics of multiple species occupying a landscape that undergoes habitat loss and fragmentation over time. The model allows exploring the effect of different habitat loss patterns, dispersal abilities, and competition mechanisms on species diversity and persistence. 

Key output patterns examined are:
- Species abundance distribution 
- Species diversity (e.g. Shannon index)
- Species occupancy and spatial distribution
- Extinction dynamics

## 2. Entities, state variables, and scales

The model contains the following entities:

**Birds** - the main mobile agents representing individuals of different species. Characterized by the state variables:
- *species* - identity number of the species (0 to max-birds-species)
- *size* - visualization size of the agent  
- *color* - visualization color scaled to the species identity

**Patches** - the spatial units forming the landscape. Characterized by: 
- *degraded* - Boolean indicating if the patch is degraded habitat or not
- *cluster* - agentset identifying which habitat fragment the patch belongs to
- *cluster_no* - patch cluster identity number  

**Globals** - model parameters and global variables

The spatial extent comprises the entire NetLogo world, which can be configured as desired (default is 51 x 51 patches). One time step represents one generation of the birds. Simulations are run for a max time configured by `end-time`

## 3. Process overview and scheduling

The model proceeds in discrete time steps representing single generations. Within each time step, the following actions occur in order:

1. Habitat loss event if the current time matches the configured loss time
2. Calculation of model probabilities for reproduction, dispersal, and replacement
3. Birds disperse stochastically based on assigned dispersal abilities and competition mechanisms
4. Data collection and recording 

The habitat loss event degrades patches according to one of three specified spatial patterns. Dispersal follows either neutral dynamics or a hierarchical competition mechanism. State variables are updated asynchronously as dispersal moves birds across the landscape.

The scheduling pseudo-code is:

```
Initialize landscape and bird populations
  
While time < end-time:

  If time = habitat loss time
    Degrade habitat patches 
  
  Calculate model probability parameters
  
  Ask patches:
    Perform probabilistic migration of birds into patch if empty
    
  Ask birds:  
    Hatch new bird in probability based on:
      - neutral dispersal  
      - hierarchy-based replacement of lower ranked species
      
    Die with configured probability
  
Collect data on model variables
  
Increment time step
```

## 4. Design concepts

**Basic principles** - The model explores two alternative hypotheses on how species divide resources: (1) neutral dynamics where species are functionally equivalent, vs (2) hierarchical competition where superior species can displace inferior ones.

**Emergence** - The spatial distribution, diversity, and abundance patterns of species emerge from the probabilistic behaviors of reproduction, dispersal, migration, and competition between individual birds.

**Adaptation** - Birds do not adapt. Their behaviors are fixed based on model configuration.

**Objectives** - Birds aim to reproduce based on fixed probabilities. They do not have explicit fitness objectives.

**Learning** - Birds do not learn.

**Prediction** - Birds do not predict future conditions. 

**Sensing** - Birds sense the occupancy of patches in their local dispersal neighborhood. With the hierarchical competition mode, they also sense the identity of other bird species present when dispersing.

**Interaction** - Birds interact by competing for space. The neutral model has equal competitive ability. The hierarchy model allows species replacement according to rank order.

**Stochasticity** - Stochasticity is implemented in multiple processes:
- Initial population placement
- Habitat loss pattern
- Dispersal distance 
- Reproduction
- Migration
- Species selection (with hierarchy)

**Collectives** - Birds do not form collectives. Patches self-organize into habitat clusters.

**Observation** - The following are recorded at each time step:
- Species abundance distribution
- Species diversity (Shannon index)
- Number of species
- Spatial distribution of birds 

## 5. Initialization

At initialization, the landscape is entirely suitable habitat. An initial number of birds are placed randomly across the landscape. Their species identity numbers are assigned randomly from 0 to the configured max unique species.

If starting with 1 individual, it is placed randomly on one edge of the world to allow immigration.

## 6. Input data

The model does not use input data from external sources.

## 7. Submodels

**Habitat loss** - Habitat patches are degraded probabilistically according to one of three spatial patterns:
1. Random loss placing magenta degraded patches randomly across the landscape.
2. Regular loss generating a fragmented landscape with regular pattern of degraded patches. 
3. Block loss using randomized squares of degraded patches.

The total amount of degradation is set by the *prob-frag* parameter.

**Dispersal** - Birds reproduce probabilistically based on fixed rates. Offspring disperse locally based on a power law distribution with an exponent chosen to match the mean dispersal distance set by the *birds-dispersal-distance* parameter. 

With neutral dynamics, they settle in any empty non-degraded patches within dispersal range. With hierarchy, they also displace resident birds of lower rank species.

**Migration** - Immigration from outside is implemented by spontaneous appearance of birds at patch edges with a fixed probability.

**Data collection** - At each time step, the model records:

- Species abundance distribution
- Shannon diversity index
- Number of unique species 
- Spatial distribution of birds

## 8. References


The model was described in: 

Saravia, L. A., & Momo, F. R. (2018). Biodiversity collapse and early warning indicators in a spatial phase transition between neutral and niche communities. Oikos, 127(1), 111–124. https://doi.org/10.1111/oik.04256