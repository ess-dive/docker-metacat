<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" encoding="UTF-8" omit-xml-declaration="yes" indent="yes" media-type="application/json"/>
    <xsl:strip-space elements="*"/>
    <xsl:variable name="APOS">'</xsl:variable>

    <!-- Grab default parameter contextURL-->
    <xsl:param name="contextURL"/>
    <xsl:param name="pid"/>
    <xsl:param name="serverName"/>
    <xsl:param name="catalogName"><![CDATA[ESS-DIVE]]></xsl:param>
    <xsl:param name="catalogId"><![CDATA[https://doi.org/10.25504/FAIRsharing.d6Pe1f]]></xsl:param>
    <xsl:param name="catalogURL"><![CDATA[https://]]><xsl:value-of select="$serverName" /></xsl:param>
    <xsl:param name="viewURL"><xsl:value-of select="$catalogURL"/><![CDATA[/view]]></xsl:param>
    <xsl:param name="url"><xsl:value-of select="$viewURL" /><![CDATA[/]]><xsl:value-of select="$pid" /></xsl:param>

    <xsl:template match="@* | node()">

        <xsl:call-template name="dataset"/>

    </xsl:template>

    <xsl:template name="dataset">
        <xsl:param name="package_id"/>
        {
        "@context": "http://schema.org/",
        "url": "<xsl:value-of select="$url"/>",
        "@type": "Dataset",
        "@id": "<xsl:value-of select="$url"/>",
        "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/title"/></xsl:call-template>",
        "includedInDataCatalog": { "name": "<xsl:value-of select="$catalogName"/>",
                                   "url": "<xsl:value-of select="$catalogURL"/>",
                                   "identifier": "<xsl:value-of select="$catalogId"/>"},
        "description":
        [
        <xsl:for-each select="dataset/abstract/para">
            "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="text()"/></xsl:call-template>"<xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        ],
        <xsl:if test="dataset/alternateIdentifier">
            "alternateName": [
            <xsl:for-each select="dataset/alternateIdentifier">
                "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="."/></xsl:call-template>"
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            ],
        </xsl:if>
        "creator": [
        <xsl:for-each  select="dataset/creator">{
            "@type": "Person",
            <xsl:if test="userId">
            "@id": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="userId"/></xsl:call-template>",
            </xsl:if>
            "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/givenName"/></xsl:call-template><xsl:text> </xsl:text><xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/surName"/></xsl:call-template>",
            "givenName":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/givenName"/></xsl:call-template>",
            "familyName":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/surName"/></xsl:call-template>"
            <xsl:if test="organizationName or electronicMailAddress">
                    <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:if test="organizationName">
                "affiliation":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="organizationName"/></xsl:call-template>"
                <xsl:if test="electronicMailAddress">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:if>
            <xsl:if test="electronicMailAddress">"email":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="electronicMailAddress"/></xsl:call-template>"</xsl:if>
            }
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        ],
        <xsl:if test="dataset/associatedParty[role='contributor']">
        "contributor": [
        <xsl:for-each select="dataset/associatedParty[role='contributor']">{
            "@type": "Person",
            <xsl:if test="userId">
            "@id": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="userId"/></xsl:call-template>",
            </xsl:if>
            "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/givenName"/></xsl:call-template><xsl:text> </xsl:text><xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/surName"/></xsl:call-template>",
            "givenName":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/givenName"/></xsl:call-template>",
            "familyName":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/surName"/></xsl:call-template>"
            <xsl:if test="organizationName or electronicMailAddress">
                    <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:if test="organizationName">
                "affiliation":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="organizationName"/></xsl:call-template>"
                <xsl:if test="electronicMailAddress">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:if>
            <xsl:if test="electronicMailAddress">"email":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="electronicMailAddress"/></xsl:call-template>"</xsl:if>
            }
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        ],
        </xsl:if>
        <xsl:if test="dataset/pubDate">"datePublished": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/pubDate"/></xsl:call-template>",</xsl:if>
        "keywords": [
        <xsl:for-each select="dataset/keywordSet[keywordThesaurus[contains(text(),'CATEGORICAL')]]">
            <xsl:for-each select="keyword">
                "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="."/></xsl:call-template>"
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        ]
        <xsl:if test="dataset/keywordSet[keywordThesaurus[contains(text(),'VARIABLE')]]">
        ,"variableMeasured": [
        <xsl:for-each select="dataset/keywordSet[keywordThesaurus[contains(text(),'VARIABLE')]]">
            <xsl:for-each select="keyword">
                "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="."/></xsl:call-template>"
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        ]
        </xsl:if>
        <xsl:if test="dataset/intellectualRights/para">
            <xsl:choose>
                <xsl:when test="contains(.,'http://creativecommons.org/licenses/by/4.0/')">
                    ,"license": "http://creativecommons.org/licenses/by/4.0/"
                </xsl:when>
                <xsl:otherwise>
                    ,"license": "http://creativecommons.org/publicdomain/zero/1.0/"
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="dataset/coverage/geographicCoverage">
            ,"spatialCoverage": [
            <xsl:for-each select="dataset/coverage/geographicCoverage">
                {
                "@type": "Place",
                <xsl:if test="geographicDescription">
                    "description": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="geographicDescription"/></xsl:call-template>",
                </xsl:if>
                <xsl:if test="boundingCoordinates">
                    "geo": [
                    {
                    "@type": "GeoCoordinates",
                    "name": "Northwest",
                    "latitude": <xsl:value-of select="translate(normalize-space( boundingCoordinates/northBoundingCoordinate),' +', '')"/>,
                    "longitude": <xsl:value-of select="translate(normalize-space( boundingCoordinates/westBoundingCoordinate),' +', '')"/>
                    },
                    {
                    "@type": "GeoCoordinates",
                    "name": "Southeast",
                    "latitude": <xsl:value-of select="translate(normalize-space( boundingCoordinates/southBoundingCoordinate),' +', '')"/>,
                    "longitude": <xsl:value-of select="translate(normalize-space( boundingCoordinates/eastBoundingCoordinate),' +', '')"/>
                    }
                    ]
                </xsl:if>
                }<xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            ]
        </xsl:if>
        <xsl:if test="dataset/project/funding">
            ,"award": [
            <xsl:for-each select="dataset/project/funding/para">
                "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="substring-after(.,'DOE:')"/></xsl:call-template>"
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            ]
        </xsl:if>
        <xsl:if test="dataset/associatedParty[role[text()='fundingOrganization']]">
            ,"funder": [
            <xsl:for-each select="dataset/associatedParty[role[text()='fundingOrganization']]">
                {
                "@type": "Organization",
                <xsl:if test="userId">
                    "@id": "<xsl:value-of select="normalize-space(userId)"/>",
                </xsl:if>
                "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="organizationName"/></xsl:call-template>"
                }
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            ]
        </xsl:if>
        <xsl:if test="dataset/coverage/temporalCoverage/rangeOfDates">
            ,"temporalCoverage":<xsl:choose>
            <xsl:when test="count(dataset/coverage/temporalCoverage/rangeOfDates) &gt; 1">[
            <xsl:for-each select="dataset/coverage/temporalCoverage/rangeOfDates">
                "<xsl:value-of select="beginDate/calendarDate"/><xsl:choose><xsl:when test="endDate/calendarDate and beginDate/calendarDate">/<xsl:value-of select="endDate/calendarDate"/></xsl:when></xsl:choose><xsl:choose><xsl:when test="not(endDate/calendarDate) and beginDate/calendarDate">..</xsl:when></xsl:choose>"
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            ]
            </xsl:when>
            <xsl:otherwise>
               "<xsl:value-of select="beginDate/calendarDate"/><xsl:choose><xsl:when test="endDate/calendarDate and beginDate/calendarDate">/<xsl:value-of select="endDate/calendarDate"/></xsl:when></xsl:choose><xsl:choose><xsl:when test="not(endDate/calendarDate) and beginDate/calendarDate">..</xsl:when></xsl:choose>"
            </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="dataset/contact[position() = 1]">
            ,"editor": {
            "@type": "Person",
            <xsl:if test="dataset/contact[position() = 1]/userId">"@id": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/userId"/></xsl:call-template>",
            </xsl:if>
            "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/individualName/givenName"/></xsl:call-template><xsl:text> </xsl:text><xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/individualName/surName"/></xsl:call-template>",
            "givenName": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/individualName/givenName"/></xsl:call-template> ",
            "familyName": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/individualName/surName"/></xsl:call-template>"<xsl:if test="dataset/contact[position() = 1]/organizationName or dataset/contact[position() = 1]/electronicMailAddress ">
                <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:if test="dataset/contact[position() = 1]/organizationName">
            "affiliation": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/organizationName"/></xsl:call-template>"<xsl:if test="dataset/contact[position() = 1]/electronicMailAddress">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:if><xsl:if test="dataset/contact[position() = 1]/electronicMailAddress">
            "email": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/electronicMailAddress"/></xsl:call-template>"
            </xsl:if>}
        </xsl:if>
        <xsl:if test="dataset/additionalInfo/section[title[text()='Related References']]/para">
            ,"citation": [
            <xsl:for-each select="dataset/additionalInfo/section[title[text()='Related References']]/para">
                "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="."/></xsl:call-template>"
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>

            ]
        </xsl:if>
        <xsl:if test="dataset/project">
            ,"provider": {
            "@type": "Organization",
            "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/title"/></xsl:call-template>",
            "member":
            {
            "@type": "Person",<xsl:if test="translate(translate(normalize-space( dataset/project/personnel/userId),' &#x9;&#xa;&#xd;', ' '), '&quot;', $APOS)">
            "@id": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/userId"/></xsl:call-template>",</xsl:if>
            "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/individualName/givenName"/></xsl:call-template><xsl:text> </xsl:text><xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/individualName/surName"/></xsl:call-template>",
            "givenName": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/individualName/givenName"/></xsl:call-template>",
            "familyName": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/individualName/surName"/></xsl:call-template>",
            "jobTitle": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/role"/></xsl:call-template>"<xsl:if test="dataset/project/personnel/electronicMailAddress or dataset/project/personnel/organizationName">
                <xsl:text>,</xsl:text>
            </xsl:if><xsl:if test="dataset/project/personnel/organizationName">
            "affiliation": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/organizationName"/></xsl:call-template>"<xsl:if test="dataset/project/personnel/electronicMailAddress">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:if><xsl:if test="dataset/project/personnel/electronicMailAddress">
            "email": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/electronicMailAddress"/></xsl:call-template>"
            </xsl:if>}
            }
        </xsl:if>
        <xsl:if test="dataset/methods">
            ,"measurementTechnique": [
            <xsl:for-each select="dataset/methods/*/*/para">
                "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="text()"/></xsl:call-template>"<xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            ]
        </xsl:if>
        <xsl:if test="dataset/otherEntity">
            ,"distribution": [
            <xsl:for-each select="dataset/otherEntity">
                {"name":"<xsl:value-of select="entityName"/>",
                "encodingFormat":"<xsl:value-of select="entityType"/>"<xsl:if test="@id">,
                "identifier": "<xsl:value-of select="@id"/>"
                </xsl:if>}
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            ]
        </xsl:if>
        }
    </xsl:template>

    <xsl:template name="transform-string">
        <xsl:param name="content"/><xsl:value-of select="translate(translate(normalize-space($content),' &#x9;&#xa;&#xd;', ' '), '&quot;', $APOS)"/>
    </xsl:template>

</xsl:stylesheet>
