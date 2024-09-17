import fetch from "cross-fetch";
import { releaseAirdrops } from "../utils/contracts/dropper";
import { execute, makePromise } from "apollo-link";
import { createHttpLink } from "apollo-link-http";
import gql from "graphql-tag";
import { Chain, CHAINS } from "../utils/chain";
import { getCurrentTimeInSecond, getDropperSubgraphURL } from "../utils/util";
import { AirdropInfo } from "../utils/interface";

async function callReleaseAirdrops(
  chain: Chain,
  froms: string[][],
  indexes: string[][],
  droppperContract: string[]
) {
  const status = await releaseAirdrops(chain, froms, indexes, droppperContract);
  if (status == 0x1) {
    return true;
  }
  return false;
}

export default async function (chainId: number) {
  console.log(`Initializing Airdrop process on chain ${chainId}...\n`);
  const chain = CHAINS.find((c) => c.id == chainId);
  if (chain == undefined) {
    console.error(`Chain with ID ${chainId} not found.`);
    return;
  }
  try {
    const currentTimestamp = await getCurrentTimeInSecond();

    const perPage = 100;
    let dataCount = 0;

    while (1) {
      const filteredAirdropData = await getInProgressAirdrops(
        chain,
        perPage,
        dataCount,
        currentTimestamp,
        "lte"
      );

      const airdropInfos: AirdropInfo[] =
        filteredAirdropData?.data?.hectorDropperContracts;

      let contracts = airdropInfos
        .filter((contract) => contract.airdrops.length > 0)
        .map((contract) => contract.address);

      let froms: string[][] = airdropInfos
        .filter((contract) => contract.airdrops.length > 0)
        .map((contract) =>
          contract.airdrops.map((airdrop) => airdrop.from.address)
        );
      let indexes: string[][] = airdropInfos
        .filter((contract) => contract.airdrops.length > 0)
        .map((contract) => contract.airdrops.map((airdrop) => airdrop.index));

      let usersLength = 0;
      for (let i = 0; i < froms.length; i++) {
        usersLength += froms[i].length;
      }

      if (contracts.length > 0 && usersLength > 0) {
        console.log(`Initializing Airdrop Release on chain ${chainId}...\n`);

        const isSuccess = await callReleaseAirdrops(
          chain,
          froms,
          indexes,
          contracts
        );
        if (!isSuccess) break;
        console.log(`Airdrop Release completed on chain ${chainId}...\n`);
      } else {
        console.log(`No Airdrop to release on chain ${chainId}...\n`);
        break;
      }

      dataCount += perPage;
    }
  } catch (error) {
    console.log(error);
    return;
  }
}

export async function getInProgressAirdrops(
  chain: Chain,
  first: number,
  skip: number,
  currentTimestamp: number,
  expiredOptions: string
) {
  const uri = getDropperSubgraphURL(chain);
  const link = createHttpLink({ uri, fetch });
  const query: string = `
    query {
            hectorDropperContracts {
              address
              id
              airdrops(first: ${first}, skip: ${skip}, where: {status: "0", releaseTime_${expiredOptions}: ${currentTimestamp}}) {
                from {
                  address
                }
                index
              }
            }
        }`;

  const operation = {
    query: gql(query),
  };

  return await makePromise(execute(link, operation));
}
