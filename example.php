<?php
require_once(__DIR__ . '/vendor/autoload.php');
// Configure HTTP basic authorization: basicAuth
$config = CareCloud\Configuration::getDefaultConfiguration()
                                 ->setUsername('YOUR_USERNAME')
                                 ->setPassword('YOUR_PASSWORD');

$apiInstance = new CareCloud\Api\CustomersApi(
// If you want use custom http client, pass your client which implements `GuzzleHttp\ClientInterface`.
// This is optional, `GuzzleHttp\Client` will be used as default.
    new GuzzleHttp\Client(),
    $config
);
$agreement_id = "agreement_id_example"; // string | The unique ID of an agreement in CareCloud
$accept_language = "cs, en-gb;q=0.8"; // string | The unique ID of the language code by ISO 639-1

try {
    $result = $apiInstance->getCustomer($agreement_id, $accept_language);
    print_r($result);
} catch (Exception $e) {
    echo 'Exception when calling AgreementsApi->getAgreement: ', $e->getMessage(), PHP_EOL;
}
