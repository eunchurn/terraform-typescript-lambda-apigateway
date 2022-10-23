import "./moduleAliases";
import { APIGatewayEvent, APIGatewayProxyResultV2 } from "aws-lambda";

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "*",
};

export const handler = async (
  event: APIGatewayEvent,
): Promise<APIGatewayProxyResultV2> => {
  console.log("Event: ", event);
  return {
    isBase64Encoded: false,
    statusCode: 200,
    headers,
    body: JSON.stringify({ message: "Hello, World" }),
  };
};
