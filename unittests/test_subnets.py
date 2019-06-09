import unittest
import json
import subprocess


class TestSubnets(unittest.TestCase):

    def test_none(self):
        result = terraform_eval('aws_subnet.this', {
            "locals": {
                "region_subnets": [],
            },
        })
        self.assertEqual(len(result), 0)

    def test_empty_subnet_name(self):
        result = terraform_eval('aws_subnet.this', {
            "locals": {
                "region_subnets": [
                    {
                        "cidr_block": "10.1.2.0/24",
                        "availability_zone": "us-west-2a",
                        "subnet_name": "",
                    },
                ],
                "name_tag_base": "override name",
            },
            "variables": {
                "tags": {
                    "Name": "default name",
                    "Environment": "foo",
                },
            },
            "resources": {
                "aws_vpc.this": {
                    "id": "vpc-mock",
                },
            },
        })
        self.assertEqual(len(result), 1)
        r = result[0]
        self.assertEqual(r.cidr_block, "10.1.2.0/24")
        self.assertEqual(r.availability_zone, "us-west-2a")
        self.assertEqual(r.vpc_id, "vpc-mock")
        self.assertEqual(r.tags, {
            "Name": "override name (us-west-2a)",
            "Environment": "foo",
        })

    def test_with_subnet_name(self):
        result = terraform_eval('aws_subnet.this', {
            "locals": {
                "region_subnets": [
                    {
                        "cidr_block": "10.1.2.0/24",
                        "availability_zone": "us-west-2a",
                        "subnet_name": "public",
                    },
                ],
                "name_tag_base": "override name",
            },
            "variables": {
                "tags": {
                    "Name": "default name",
                    "Environment": "foo",
                },
            },
            "resources": {
                "aws_vpc.this": {
                    "id": "vpc-mock",
                },
            },
        })
        self.assertEqual(len(result), 1)
        r = result[0]
        self.assertEqual(r.cidr_block, "10.1.2.0/24")
        self.assertEqual(r.availability_zone, "us-west-2a")
        self.assertEqual(r.vpc_id, "vpc-mock")
        self.assertEqual(r.tags, {
            "Name": "override name (us-west-2a, public)",
            "Environment": "foo",
        })


def terraform_eval(addr, mock_data):
    mock_data_json = json.dumps(mock_data)

    proc = subprocess.Popen(
        ['terraform', 'testing', 'eval', '../', addr, '-'],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    (out, err) = proc.communicate(mock_data_json)

    try:
        result_raw = json.loads(out)
    except:
        raise RuntimeError(err)

    if "diagnostics" in result_raw:
        errs = [diag for diag in result_raw["diagnostics"]
                if diag["severity"] == "error"]
        if len(errs) > 0:
            raise RuntimeError(errs)

    return prepare_result(result_raw["value"], result_raw["type"])


def prepare_result(rawVal, ty):
    class Object(object):
        pass

    if rawVal == None:
        return None

    if isinstance(ty, list):
        kind = ty[0]
        if kind == "object":
            ret = Object()
            for k, v in rawVal.iteritems():
                attrTy = ty[1][k]
                setattr(ret, k, prepare_result(v, attrTy))
            return ret
        if kind == "tuple":
            return [prepare_result(v, ty[1][i]) for i, v in enumerate(rawVal)]
        elif kind == "list":
            return [prepare_result(v, ty[1]) for v in rawVal]
        elif kind == "map":
            return {k: prepare_result(v, ty[1]) for k, v in rawVal.iteritems()}
        elif kind == "set":
            # Not using set here because not all of our representations are hashable
            return [prepare_result(v, ty[1]) for v in rawVal]

    return rawVal
