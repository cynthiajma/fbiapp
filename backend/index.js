const { ApolloServer, gql } = require('apollo-server');

const typeDefs = gql`
  type Query {
    childProfile(id: ID!): Child
    characterLibrary: [Character]
  }

  type Mutation {
    logFeeling(childId: ID!, characterId: ID!, level: Int!): Log
    updateProfile(childId: ID!, accessories: [String]): Child
  }

  type Child {
    id: ID!
    username: String!
    age: Int
    profile: Profile
  }

  type Character {
    id: ID!
    name: String!
    feeling: String!
    musicUrl: String
  }

  type Log {
    id: ID!
    childId: ID!
    characterId: ID!
    level: Int!
    timestamp: String!
  }

  type Profile {
    accessories: [String]
  }
`;

const sampleChild = {
  id: '1',
  username: 'child1',
  age: 10,
  profile: { accessories: ['hat', 'glasses'] }
};

const sampleCharacters = [
  { id: 'c1', name: 'Happy', feeling: 'joy', musicUrl: 'http://...' },
  { id: 'c2', name: 'Sad', feeling: 'sadness', musicUrl: 'http://...' }
];

const resolvers = {
  Query: {
    childProfile: (_, { id }) => sampleChild,
    characterLibrary: () => sampleCharacters,
  },
  Mutation: {
    logFeeling: (_, { childId, characterId, level }) => ({
      id: 'log1',
      childId,
      characterId,
      level,
      timestamp: new Date().toISOString(),
    }),
    updateProfile: (_, { childId, accessories }) => ({
      id: childId,
      username: 'child1',
      age: 10,
      profile: { accessories },
    }),
  },
};

const server = new ApolloServer({ typeDefs, resolvers });

server.listen().then(({ url }) => {
  console.log(`🚀 Server ready at ${url}`);
});
