const fs = require('fs')
const path = require('path')

const testConfigs = {
  'fapi1-advanced': [
    { variant: { client_auth_type: 'private_key_jwt', fapi_auth_request_method: 'by_value', fapi_profile: 'plain_fapi', fapi_response_mode: 'plain_response' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi1-advanced-final-with-private-key-PS256-PS256-automated.json', certificationProfile: 'FAPI Adv. OP w/ Private Key' },
    { variant: { client_auth_type: 'private_key_jwt', fapi_auth_request_method: 'by_value', fapi_profile: 'plain_fapi', fapi_response_mode: 'plain_response' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi1-advanced-final-with-private-key-ES256-ES256-automated.json', certificationProfile: 'FAPI Adv. OP w/ Private Key' },
    { variant: { client_auth_type: 'mtls', fapi_auth_request_method: 'by_value', fapi_profile: 'plain_fapi', fapi_response_mode: 'plain_response' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi1-advanced-final-with-mtls-PS256-PS256-automated.json', certificationProfile: 'FAPI Adv. OP w/ MTLS' },
    { variant: { client_auth_type: 'mtls', fapi_auth_request_method: 'by_value', fapi_profile: 'plain_fapi', fapi_response_mode: 'plain_response' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi1-advanced-final-with-mtls-ES256-ES256-automated.json', certificationProfile: 'FAPI Adv. OP w/ MTLS' },
    { variant: { client_auth_type: 'private_key_jwt', fapi_auth_request_method: 'pushed', fapi_profile: 'plain_fapi', fapi_response_mode: 'plain_response' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi1-advanced-par-private-key-PS256-PS256-automated.json', certificationProfile: 'FAPI Adv. OP w/ Private Key, PAR' },
    { variant: { client_auth_type: 'private_key_jwt', fapi_auth_request_method: 'pushed', fapi_profile: 'plain_fapi', fapi_response_mode: 'plain_response' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi1-advanced-par-private-key-ES256-ES256-automated.json', certificationProfile: 'FAPI Adv. OP w/ Private Key, PAR' },
    { variant: { client_auth_type: 'mtls', fapi_auth_request_method: 'pushed', fapi_profile: 'plain_fapi', fapi_response_mode: 'plain_response' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi1-advanced-par-mtls-PS256-PS256-automated.json', certificationProfile: 'FAPI Adv. OP w/ MTLS, PAR' },
    { variant: { client_auth_type: 'mtls', fapi_auth_request_method: 'pushed', fapi_profile: 'plain_fapi', fapi_response_mode: 'plain_response' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi1-advanced-par-mtls-ES256-ES256-automated.json', certificationProfile: 'FAPI Adv. OP w/ MTLS, PAR' },
    { variant: { client_auth_type: 'private_key_jwt', fapi_auth_request_method: 'by_value', fapi_profile: 'plain_fapi', fapi_response_mode: 'jarm' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi1-advanced-jarm-private-key-PS256-PS256-automated.json', certificationProfile: 'FAPI Adv. OP w/ Private Key, JARM' },
    { variant: { client_auth_type: 'private_key_jwt', fapi_auth_request_method: 'by_value', fapi_profile: 'plain_fapi', fapi_response_mode: 'jarm' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi1-advanced-jarm-private-key-ES256-ES256-automated.json', certificationProfile: 'FAPI Adv. OP w/ Private Key, JARM' },
    { variant: { client_auth_type: 'mtls', fapi_auth_request_method: 'by_value', fapi_profile: 'plain_fapi', fapi_response_mode: 'jarm' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi1-advanced-jarm-mtls-PS256-PS256-automated.json', certificationProfile: 'FAPI Adv. OP w/ MTLS, JARM' },
    { variant: { client_auth_type: 'mtls', fapi_auth_request_method: 'by_value', fapi_profile: 'plain_fapi', fapi_response_mode: 'jarm' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi1-advanced-jarm-mtls-ES256-ES256-automated.json', certificationProfile: 'FAPI Adv. OP w/ MTLS, JARM' },
    { variant: { client_auth_type: 'private_key_jwt', fapi_auth_request_method: 'pushed', fapi_profile: 'plain_fapi', fapi_response_mode: 'jarm' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi1-advanced-par-jarm-private-key-PS256-PS256-automated.json', certificationProfile: 'FAPI Adv. OP w/ Private Key, PAR, JARM' },
    { variant: { client_auth_type: 'private_key_jwt', fapi_auth_request_method: 'pushed', fapi_profile: 'plain_fapi', fapi_response_mode: 'jarm' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi1-advanced-par-jarm-private-key-ES256-ES256-automated.json', certificationProfile: 'FAPI Adv. OP w/ Private Key, PAR, JARM' },
    { variant: { client_auth_type: 'mtls', fapi_auth_request_method: 'pushed', fapi_profile: 'plain_fapi', fapi_response_mode: 'jarm' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi1-advanced-par-jarm-mtls-PS256-PS256-automated.json', certificationProfile: 'FAPI Adv. OP w/ MTLS, PAR, JARM' },
    { variant: { client_auth_type: 'mtls', fapi_auth_request_method: 'pushed', fapi_profile: 'plain_fapi', fapi_response_mode: 'jarm' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi1-advanced-par-jarm-mtls-ES256-ES256-automated.json', certificationProfile: 'FAPI Adv. OP w/ MTLS, PAR, JARM' }
  ],
  'fapi2-sp-final': [
    { variant: { sender_constrain: 'dpop', client_auth_type: 'mtls', authorization_request_type: 'simple', openid: 'plain_oauth', fapi_profile: 'plain_fapi' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi2-final-FAPI2SP-DPOP-MTLS-MTLS-ES256-ES256-automated.json', certificationProfile: 'FAPI2SP OP MTLS + DPoP' },
    { variant: { sender_constrain: 'dpop', client_auth_type: 'private_key_jwt', authorization_request_type: 'simple', openid: 'plain_oauth', fapi_profile: 'plain_fapi' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi2-final-FAPI2SP-DPOP-private-key-MTLS-PS256-PS256-automated.json', certificationProfile: 'FAPI2SP OP private key + DPoP' },
    { variant: { sender_constrain: 'dpop', client_auth_type: 'mtls', authorization_request_type: 'simple', openid: 'openid_connect', fapi_profile: 'plain_fapi' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi2-final-FAPI2SP-OpenID-Connect-DPOP-ES256-ES256-automated.json', certificationProfile: 'FAPI2SP OP OpenID Connect, FAPI2SP OP MTLS + DPoP' },
    { variant: { sender_constrain: 'mtls', client_auth_type: 'mtls', authorization_request_type: 'simple', openid: 'plain_oauth', fapi_profile: 'plain_fapi' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi2-final-FAPI2SP-MTLS-MTLS-ES256-ES256-automated.json', certificationProfile: 'FAPI2SP OP MTLS + MTLS' },
    { variant: { sender_constrain: 'mtls', client_auth_type: 'private_key_jwt', authorization_request_type: 'simple', openid: 'plain_oauth', fapi_profile: 'plain_fapi' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi2-final-FAPI2SP-private-key-MTLS-PS256-PS256-automated.json', certificationProfile: 'FAPI2SP OP private key + MTLS' },
    { variant: { sender_constrain: 'mtls', client_auth_type: 'mtls', authorization_request_type: 'simple', openid: 'openid_connect', fapi_profile: 'plain_fapi' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi2-final-FAPI2SP-OpenID-Connect-ES256-ES256-automated.json', certificationProfile: 'FAPI2SP OP OpenID Connect, FAPI2SP OP MTLS + MTLS' }
  ],
  'fapi2-ms-final': [
    { variant: { sender_constrain: 'dpop', client_auth_type: 'mtls', authorization_request_type: 'simple', openid: 'plain_oauth', fapi_request_method: 'signed_non_repudiation', fapi_profile: 'plain_fapi', fapi_response_mode: 'plain_response' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi2-final-FAPI2MS-DPOP-JAR-MTLS-MTLS-ES256-ES256-automated.json', certificationProfile: 'FAPI2SP OP MTLS + DPoP, FAPI2MS OP JAR' },
    { variant: { sender_constrain: 'dpop', client_auth_type: 'mtls', authorization_request_type: 'simple', openid: 'plain_oauth', fapi_request_method: 'signed_non_repudiation', fapi_profile: 'plain_fapi', fapi_response_mode: 'jarm' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi2-final-FAPI2MS-DPOP-JARM-MTLS-MTLS-ES256-ES256-automated.json', certificationProfile: 'FAPI2SP OP MTLS + DPoP, FAPI2MS OP JAR, FAPI2MS OP JARM' },
    { variant: { sender_constrain: 'mtls', client_auth_type: 'mtls', authorization_request_type: 'simple', openid: 'plain_oauth', fapi_request_method: 'signed_non_repudiation', fapi_profile: 'plain_fapi', fapi_response_mode: 'plain_response' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi2-final-FAPI2MS-JAR-MTLS-MTLS-ES256-ES256-automated.json', certificationProfile: 'FAPI2SP OP MTLS + MTLS, FAPI2MS OP JAR' },
    { variant: { sender_constrain: 'mtls', client_auth_type: 'mtls', authorization_request_type: 'simple', openid: 'plain_oauth', fapi_request_method: 'signed_non_repudiation', fapi_profile: 'plain_fapi', fapi_response_mode: 'jarm' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi2-final-FAPI2MS-JARM-MTLS-MTLS-ES256-ES256-automated.json', certificationProfile: 'FAPI2SP OP MTLS + MTLS, FAPI2MS OP JAR, FAPI2MS OP JARM' },
    { variant: { sender_constrain: 'mtls', client_auth_type: 'private_key_jwt', authorization_request_type: 'simple', openid: 'plain_oauth', fapi_request_method: 'signed_non_repudiation', fapi_profile: 'plain_fapi', fapi_response_mode: 'plain_response' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi2-final-FAPI2MS-JAR-private-key-MTLS-ES256-ES256-automated.json', certificationProfile: 'FAPI2SP OP private key + MTLS, FAPI2MS OP JAR' },
    { variant: { sender_constrain: 'mtls', client_auth_type: 'private_key_jwt', authorization_request_type: 'simple', openid: 'plain_oauth', fapi_request_method: 'signed_non_repudiation', fapi_profile: 'plain_fapi', fapi_response_mode: 'jarm' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi2-final-FAPI2MS-JARM-private-key-MTLS-PS256-PS256-automated.json', certificationProfile: 'FAPI2SP OP private key + MTLS, FAPI2MS OP JAR, FAPI2MS OP JARM' },
    { variant: { sender_constrain: 'dpop', client_auth_type: 'private_key_jwt', authorization_request_type: 'simple', openid: 'plain_oauth', fapi_request_method: 'signed_non_repudiation', fapi_profile: 'plain_fapi', fapi_response_mode: 'plain_response' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi2-final-FAPI2MS-DPOP-JAR-private-key-MTLS-PS256-PS256-automated.json', certificationProfile: 'FAPI2SP OP private key + DPoP, FAPI2MS OP JAR' },
    { variant: { sender_constrain: 'dpop', client_auth_type: 'private_key_jwt', authorization_request_type: 'simple', openid: 'plain_oauth', fapi_request_method: 'signed_non_repudiation', fapi_profile: 'plain_fapi', fapi_response_mode: 'jarm' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi2-final-FAPI2MS-DPOP-JARM-private-key-MTLS-ES256-ES256-automated.json', certificationProfile: 'FAPI2SP OP private key + DPoP, FAPI2MS OP JAR, FAPI2MS OP JARM' }
  ],
  'fapi-ciba': [
    { variant: { client_auth_type: 'private_key_jwt', fapi_ciba_profile: 'plain_fapi', ciba_mode: 'poll', client_registration: 'static_client' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi-ciba-id1-poll-private-key-PS256-PS256-automated.json', certificationProfile: 'FAPI-CIBA OP poll w/ Private Key' },
    { variant: { client_auth_type: 'private_key_jwt', fapi_ciba_profile: 'plain_fapi', ciba_mode: 'poll', client_registration: 'static_client' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi-ciba-id1-poll-private-key-ES256-ES256-automated.json', certificationProfile: 'FAPI-CIBA OP poll w/ Private Key' },
    { variant: { client_auth_type: 'mtls', fapi_ciba_profile: 'plain_fapi', ciba_mode: 'poll', client_registration: 'static_client' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi-ciba-id1-poll-mtls-PS256-PS256-automated.json', certificationProfile: 'FAPI-CIBA OP poll w/ MTLS' },
    { variant: { client_auth_type: 'mtls', fapi_ciba_profile: 'plain_fapi', ciba_mode: 'poll', client_registration: 'static_client' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi-ciba-id1-poll-mtls-ES256-ES256-automated.json', certificationProfile: 'FAPI-CIBA OP poll w/ MTLS' },
    { variant: { client_auth_type: 'private_key_jwt', fapi_ciba_profile: 'plain_fapi', ciba_mode: 'ping', client_registration: 'static_client' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi-ciba-id1-ping-private-key-PS256-PS256-automated.json', certificationProfile: 'FAPI-CIBA OP ping w/ Private Key' },
    { variant: { client_auth_type: 'private_key_jwt', fapi_ciba_profile: 'plain_fapi', ciba_mode: 'ping', client_registration: 'static_client' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi-ciba-id1-ping-private-key-ES256-ES256-automated.json', certificationProfile: 'FAPI-CIBA OP ping w/ Private Key' },
    { variant: { client_auth_type: 'mtls', fapi_ciba_profile: 'plain_fapi', ciba_mode: 'ping', client_registration: 'static_client' }, signatureAlgorithm: 'RequestObject:PS256/IDToken:PS256', configFile: 'fapi-ciba-id1-ping-mtls-PS256-PS256-automated.json', certificationProfile: 'FAPI-CIBA OP ping w/ MTLS' },
    { variant: { client_auth_type: 'mtls', fapi_ciba_profile: 'plain_fapi', ciba_mode: 'ping', client_registration: 'static_client' }, signatureAlgorithm: 'RequestObject:ES256/IDToken:ES256', configFile: 'fapi-ciba-id1-ping-mtls-ES256-ES256-automated.json', certificationProfile: 'FAPI-CIBA OP ping w/ MTLS' }
  ]
}

const workspace = process.env.GITHUB_WORKSPACE || '.'
const directory = path.resolve('./matrix-job-outputs')
const allResults = []
const allTestTimings = []

for (const dirName of fs.readdirSync(directory)) {
  const readFilePath = path.join(directory, dirName, 'outputs.txt')
  if (!fs.existsSync(readFilePath)) continue

  const profileMatch = dirName.match(/conformance-test-outputs-(.+)/)
  const profileName = profileMatch ? profileMatch[1] : dirName

  const content = fs.readFileSync(readFilePath, 'utf8')
  const lines = content.split('\n')

  // Parse per-variant results by matching "Results for [N] ... with configuration <config>"
  // followed by "Overall totals: ran N test modules..." lines
  // Log lines may have timestamp and container name prefixes, so match loosely
  const resultsHeaderPattern = /Results for \[\d+\] .+ with configuration (.+):\s*$/
  const totalsPattern = /Overall totals: ran (\d+) test modules\. Conditions: (\d+) successes, (\d+) failures, (\d+) warnings\. ([\d.]+) seconds/
  const failPattern = /[1-9] FAILURE, /
  const failTestPattern = / Test ([\w-]+)/

  const perVariantResults = {}
  const perConfigTestTimings = {}
  const pendingTestTimings = []
  const failedTests = []
  let currentConfigFile = null

  // Pattern for individual test result lines from run-test-plan.py
  // Format: Test [plan:module] test-name[variants] module-id STATUS - result RESULT. N log entries - N SUCCESS N FAILURE, N WARNING, X.X seconds
  // ANSI color codes may be present, so strip them before matching
  const stripAnsi = (str) => str.replace(/\x1b\[[0-9;]*m/g, '')
  const testResultLinePattern = /Test \[\d+:\d+\] ([\w-]+)(?:\[.*?\])* \S+ \S+ - result \S+\. \d+ log entries - \d+ SUCCESS \d+ FAILURE, \d+ WARNING, ([\d.]+) seconds/

  for (const line of lines) {
    const headerMatch = line.match(resultsHeaderPattern)
    if (headerMatch) {
      // Extract basename from the full config path
      const fullPath = headerMatch[1].trim()
      currentConfigFile = fullPath.split('/').pop()
      // Associate buffered test timings with this config
      perConfigTestTimings[currentConfigFile] = [...pendingTestTimings]
      pendingTestTimings.length = 0
      continue
    }
    const totalsMatch = line.match(totalsPattern)
    if (totalsMatch && currentConfigFile) {
      perVariantResults[currentConfigFile] = {
        testModules: parseInt(totalsMatch[1]),
        conditions: {
          successes: parseInt(totalsMatch[2]),
          failures: parseInt(totalsMatch[3]),
          warnings: parseInt(totalsMatch[4])
        },
        elapsedTimeInSeconds: parseFloat(totalsMatch[5])
      }
      currentConfigFile = null
    }
    if (failPattern.test(line)) {
      const result = line.match(failTestPattern)
      if (result) failedTests.push(result[1])
    }
    const cleanLine = stripAnsi(line)
    const testResultMatch = cleanLine.match(testResultLinePattern)
    if (testResultMatch) {
      const timing = {
        testPlanName: profileName,
        testName: testResultMatch[1],
        elapsedTimeInSeconds: parseFloat(testResultMatch[2])
      }
      allTestTimings.push(timing)
      pendingTestTimings.push(timing)
    }
  }

  // Match per-variant results to configs and compute test plan totals
  const configs = testConfigs[profileName] || []
  const planTotals = { testModules: 0, conditions: { successes: 0, failures: 0, warnings: 0 }, elapsedTimeInSeconds: 0 }

  for (const c of configs) {
    const variantResult = perVariantResults[c.configFile] || null
    c.results = variantResult
    if (variantResult) {
      planTotals.testModules += variantResult.testModules
      planTotals.conditions.successes += variantResult.conditions.successes
      planTotals.conditions.failures += variantResult.conditions.failures
      planTotals.conditions.warnings += variantResult.conditions.warnings
      planTotals.elapsedTimeInSeconds += variantResult.elapsedTimeInSeconds
    }
  }
  planTotals.elapsedTimeInSeconds = Math.round(planTotals.elapsedTimeInSeconds * 10) / 10

  // Console output
  console.log('')
  console.log('========================================')
  console.log(`Test Plan Name: ${profileName}`)
  console.log('========================================')

  for (let i = 0; i < configs.length; i++) {
    const c = configs[i]
    console.log(`\n  [${i + 1}] Variant:`)
    for (const [key, value] of Object.entries(c.variant)) {
      console.log(`      ${key}: ${value}`)
    }
    console.log(`  Signature Algorithm: ${c.signatureAlgorithm}`)
    console.log(`  Config File: ${c.configFile}`)
    console.log(`  Certification Profile: ${c.certificationProfile}`)
    if (c.results) {
      console.log(`  testModules: ${c.results.testModules}`)
      console.log('  conditions:')
      console.log(`    successes: ${c.results.conditions.successes}`)
      console.log(`    failures: ${c.results.conditions.failures}`)
      console.log(`    warnings: ${c.results.conditions.warnings}`)
      console.log(`  elapsedTimeInSeconds: ${c.results.elapsedTimeInSeconds}`)
    } else {
      console.log('  (No results found for this variant)')
    }
    const variantTimings = (perConfigTestTimings[c.configFile] || [])
      .sort((a, b) => b.elapsedTimeInSeconds - a.elapsedTimeInSeconds)
    if (variantTimings.length > 0) {
      console.log(`  All Tests by Completion Time:`)
      for (let j = 0; j < variantTimings.length; j++) {
        console.log(`    ${j + 1}. ${variantTimings[j].testName} - ${variantTimings[j].elapsedTimeInSeconds} seconds`)
      }
    }
  }

  const hasResults = configs.some(c => c.results)
  console.log('')
  console.log('  ----------------------------------------')
  console.log(`  Test Plan Totals (${profileName}):`)
  if (hasResults) {
    console.log(`  testModules: ${planTotals.testModules}`)
    console.log('  conditions:')
    console.log(`    successes: ${planTotals.conditions.successes}`)
    console.log(`    failures: ${planTotals.conditions.failures}`)
    console.log(`    warnings: ${planTotals.conditions.warnings}`)
    console.log(`  elapsedTimeInSeconds: ${planTotals.elapsedTimeInSeconds}`)
  } else {
    console.log('  (No results found)')
  }

  if (failedTests.length > 0) {
    console.log('')
    console.log('  Failed Tests:')
    for (const t of failedTests) {
      console.log(`    - ${t}`)
    }
  }

  allResults.push({
    testPlanName: profileName,
    configurations: configs,
    planTotals: hasResults ? planTotals : null,
    failedTests: failedTests
  })
}

// Output top 10 time-consuming tests across all profiles
allTestTimings.sort((a, b) => b.elapsedTimeInSeconds - a.elapsedTimeInSeconds)
const top10 = allTestTimings.slice(0, 10)
console.log('')
console.log('========================================')
console.log('Top 10 Time-Consuming Tests')
console.log('========================================')
for (let i = 0; i < top10.length; i++) {
  const t = top10[i]
  console.log(`  ${i + 1}. [${t.testPlanName}] ${t.testName} - ${t.elapsedTimeInSeconds} seconds`)
}
if (top10.length === 0) {
  console.log('  (No individual test timing data found)')
}
console.log('')

fs.writeFileSync(path.join(workspace, 'all-tests-outputs.txt'), JSON.stringify(allResults, null, 2))
