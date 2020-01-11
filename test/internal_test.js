const assert = require('assert');
const fp = require("find-free-port")

const fetch = require('isomorphic-fetch');

const express = require('express');
const Router = require('express-promise-router')

const appUnderTest = require('../app.js');

// Get database URL from config
require('dotenv').config();

const allGroupsQuery =
	`
	{
		allGroups {
			nodes {
				email
				labels
				fullname
				github
				wechat
				status
				lastRefresh
			}
		}
	}
	`;

const properties =	[
	'email',
	'fullname',
	'github',
	'labels',
	'lastRefresh',
	'status',
	'wechat',
];

describe('internal schema', () => {

	beforeEach((done) => {
		fp(3000).then(([freep]) => {
			this.port = freep;
			query = appUnderTest.createQuery(process.env.DATABASE_URL);
			router = appUnderTest.createRouter(new Router(), query);
			server = appUnderTest.createServer(
				express(), router, '/gsuite', process.env.TESTAPIKEY, freep);
			done();
		}).catch((err)=>{
			done(err);
		});
	});

	it('can query all groups', (done) => {
		fetch( `http://localhost:${this.port}/internal/graphql`, {
			body: JSON.stringify({query: allGroupsQuery}),
			method: 'POST',
			headers: {
				"Content-Type": "application/json; charset=utf-8",
				"Cookie": `apikey=${process.env.TESTAPIKEY}`,
			}

		})
			.then((response) => {
				if (response.status >= 400) {
						throw new Error(`Bad response from server: ${JSON.stringify(response)}`);
				}
				return response.json();
			})
			.then((result) => {
					if(!result.data) {
						throw new Error(`missing expected results with {data: {allGroups}}: ${Object.keys(result)}`);
					}
					if(!result.data.allGroups) {
						throw new Error(`missing expected results with {data: {allGroups}}: ${Object.keys(result.data)}`);
					}
					//console.log(JSON.stringify(result.data.allGroups.nodes));
					var keys = Object.keys(result.data.allGroups.nodes[0])
					keys.sort();
					if(JSON.stringify(keys) !=  JSON.stringify(properties)) {
						throw new Error(`key(s) missing ${keys}`);
					}
					done();
			})
			.catch((err) => {
				done(err);
			});
	});

	it('Can NOT query with invalid apikey', (done) => {
		fetch(`http://localhost:${this.port}/internal/graphql`, {
			body: JSON.stringify({query: allGroupsQuery}),
			method: 'POST',
			headers: {
				"Content-Type": "application/json; charset=utf-8",
				"Cookie": "apikey=WRONG_APIKEY",
			}
		})
		.then((response) => {
			if(response.status != 400) {
				throw new Error("Status code should be 400: Bad request");
			}
			
			return response.json();
		})
		.then((result) => {
			const expected = { 'error': 'invalid api key for /internal/graphql'};
			if(result.error == expected.error) {
				done();
			}
			else
			{
				throw new Error(`Response should be ${JSON.stringify(expected, null, 4)}`);
			}
		})
		.catch((err) => { done(err) });
	});
});
